pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../modules/SafeMath.sol";
import "./leverageFactoryData.sol";
import "../proxy/fnxProxy.sol";
import "../leveragedPool/ILeveragedPool.sol";
import "../stakePool/IStakePool.sol";
import "../ERC20/IERC20.sol";
import "../rebaseToken/IRebaseToken.sol";
import "../FPTCoin/IFPTCoin.sol";
import "../modules/Address.sol";
/**
 * @title FNX period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
 *
 */
contract leverageFactory is leverageFactoryData{
    using SafeMath for uint256;
    using Address for address;
    constructor() public {

    } 
    function initialize() public{
        versionUpdater.initialize();
        FPTTimeLimit = 0;
        rebaseTimeLimit = 0;
    }
    function update() public onlyOwner versionUpdate {
    }
    function initFactoryInfo(string memory _baseCoinName,address _stakePoolImpl,address _leveragePoolImpl,address _FPTCoinImpl,
        address _rebaseTokenImpl,address _fnxOracle,address _uniswap,address payable _feeAddress,uint64 _rebalanceInterval,
             uint64 _buyFee, uint64 _sellFee, uint64 _rebalanceFee,uint64 _rebaseThreshold,uint64 _liquidateThreshold,uint64 _interestInflation) public onlyOwner{
                baseCoinName = _baseCoinName;
                proxyinfoMap[LeveragePoolID].implementation = _leveragePoolImpl;
                proxyinfoMap[stakePoolID].implementation = _stakePoolImpl;
                proxyinfoMap[rebasePoolID].implementation = _rebaseTokenImpl;
                proxyinfoMap[FPTTokenID].implementation = _FPTCoinImpl;
                fnxOracle = _fnxOracle;
                uniswap = _uniswap;
                feeAddress = _feeAddress;
                buyFee = _buyFee;
                sellFee = _sellFee;
                rebalanceFee = _rebalanceFee;
                rebaseThreshold = _rebaseThreshold;
                liquidateThreshold = _liquidateThreshold;
                interestInflation = _interestInflation;
                rebalanceInterval = _rebalanceInterval;
             }
    function createLeveragePool(address tokenA,address tokenB,uint64 leverageRatio,
        uint256 leverageRebaseWorth)external 
        onlyOwner returns (address payable _leveragePool){
        bytes32 poolKey = getPairHash(tokenA,tokenB,leverageRatio);
        _leveragePool = leveragePoolMap[poolKey];
        if(_leveragePool == address(0)){
            _leveragePool = createLeveragePool_sub(tokenA,tokenB,leverageRatio,leverageRebaseWorth);
            leveragePoolMap[poolKey] = _leveragePool;
        }
    }
    function createLeveragePool_sub(address tokenA,address tokenB,uint64 leverageRatio,
        uint256 leverageRebaseWorth)internal returns (address payable _leveragePool){
        address _stakePoolA = getStakePool(tokenA);
        address _stakePoolB = getStakePool(tokenB);
        require(_stakePoolA!=address(0) && _stakePoolB!=address(0),"Stake pool is not created");
        _leveragePool = createFnxProxy(LeveragePoolID);
        IStakePool(_stakePoolA).modifyPermission(_leveragePool,0xFFFFFFFFFFFFFFFF);
        IStakePool(_stakePoolB).modifyPermission(_leveragePool,0xFFFFFFFFFFFFFFFF);
        setLeveragePoolInfo_sub(_stakePoolA,_stakePoolB,_leveragePool,tokenA,tokenB,leverageRatio,leverageRebaseWorth);
        
    }
    function setLeveragePoolInfo_sub(address _stakePoolA,address _stakePoolB,address payable _leveragePool,
        address tokenA,address tokenB,uint64 leverageRatio,
        uint256 leverageRebaseWorth) internal {
        address rebaseTokenA;
        address rebaseTokenB;
        {
            string memory token1 = (tokenB == address(0)) ? baseCoinName : IERC20(tokenB).symbol();
            string memory suffix = leverageSuffix(leverageRatio);
            string memory leverageName = string(abi.encodePacked(token1,"_BULL",suffix));
            string memory hedgeName = string(abi.encodePacked(token1,"_BEAR",suffix));
            rebaseTokenA = createRebaseToken(_leveragePool,tokenA,leverageName);
            rebaseTokenB = createRebaseToken(_leveragePool,tokenB,hedgeName);
        }
        ILeveragedPool newPool = ILeveragedPool(_leveragePool);
        newPool.setLeveragePoolInfo(feeAddress,_stakePoolA,_stakePoolB,fnxOracle,uniswap,rebaseTokenA,rebaseTokenB,
            uint256(buyFee)+(uint256(sellFee)<<64)+(uint256(rebalanceFee)<<128)+(uint256(leverageRatio)<<192),
            rebaseThreshold +(uint256(liquidateThreshold)<<128),leverageRebaseWorth);
    }
    function createRebaseToken(address leveragePool,address token,string memory name)internal returns(address){
        address payable newToken = createFnxProxy(rebasePoolID);
        IRebaseToken rebaseToken = IRebaseToken(newToken);
        Operator(newToken).setManager(leveragePool);
        rebaseToken.changeTokenName(name,name,token);
        rebaseToken.setTimeLimitation(rebaseTimeLimit);
        return newToken;
    }
    function getLeveragePool(address tokenA,address tokenB,uint256 leverageRatio)external 
        view returns (address _stakePoolA,address _stakePoolB,address _leveragePool){
        _stakePoolA = stakePoolMap[tokenA];
        _stakePoolB = stakePoolMap[tokenB];
        bytes32 poolKey = getPairHash(tokenA,tokenB,leverageRatio);
        _leveragePool = leveragePoolMap[poolKey];
    }
    function getStakePool(address token)public view returns (address _stakePool){
        _stakePool = stakePoolMap[token];
    }
    function getAllStakePool()external view returns (address payable[] memory){
        return proxyinfoMap[stakePoolID].proxyList;
    }
    function getAllLeveragePool()external view returns (address payable[] memory){
        return proxyinfoMap[LeveragePoolID].proxyList;
    }
    function setRebalanceInterval(uint64 interval) public onlyOwner{
        rebalanceInterval = interval;
    }
    function rebalanceAll()external rebalanceEnable onlyOperator(3) {
        proxyInfo storage leverageInfo = proxyinfoMap[LeveragePoolID];
        uint256 len = leverageInfo.proxyList.length;
        for(uint256 i=0;i<len;i++){
            ILeveragedPool(leverageInfo.proxyList[i]).rebalance();
        }
        proxyInfo storage stakeInfo = proxyinfoMap[stakePoolID];
        uint64 inflation = interestInflation;
        len = stakeInfo.proxyList.length;
        for(uint256 i=0;i<len;i++){
            IStakePool(stakeInfo.proxyList[i]).interestInflation(inflation);
        }
    }
    function getPairHash(address tokenA,address tokenB,uint256 leverageRatio) internal pure returns (bytes32) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encodePacked(token0, token1,leverageRatio));
    }
    function createStatePool(address token,uint64 _interestrate)public onlyOwner returns(address payable){
        address payable stakePool = stakePoolMap[token];
        if(stakePool == address(0)){
            address fptCoin = createFptCoin(token);
            stakePool = createFnxProxy(stakePoolID);
            IStakePool(stakePool).setPoolInfo(fptCoin,token,_interestrate);
            Operator(fptCoin).setManager(stakePool);
            stakePoolMap[token] = stakePool;
        }
        return stakePool;
    }
    function createFptCoin(address token)internal returns(address){
        address payable newCoin = createFnxProxy(FPTTokenID);
        string memory tokenName = (token == address(0)) ? string(abi.encodePacked("FPT_", baseCoinName)):
                 string(abi.encodePacked("FPT_",IERC20(token).symbol()));
        IFPTCoin(newCoin).changeTokenName(tokenName,tokenName,IERC20(token).decimals());
        return newCoin;
    }
    function createFnxProxy(uint256 index) internal returns (address payable){
        proxyInfo storage curInfo = proxyinfoMap[index];
        fnxProxy newProxy = new fnxProxy(curInfo.implementation);
        curInfo.proxyList.push(address(newProxy));
        return address(newProxy);
    }
    function setInterestRate(address token,uint64 rate)public onlyOwner{
        address _stakePool = getStakePool(token);
        require(_stakePool != address(0),"stakePool is not found!");
        IStakePool(_stakePool).setInterestRate(rate);
    }
    function setContractsInfo(uint256 index,bytes memory data)internal{
        proxyInfo storage curInfo = proxyinfoMap[index];
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            Address.functionCall(curInfo.proxyList[i],data,"setContractsInfo error");
        }
    }

    function setUniswapAddress(address _uniswap)public onlyOwner{
        uniswap = _uniswap;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setUniswapAddress(address)",_uniswap));
    }
    function setOracleAddress(address _fnxOracle)public onlyOwner{
        fnxOracle = _fnxOracle;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setOracleAddress(address)",_fnxOracle));
    }
    function setFeeAddress(address payable _feeAddress)public onlyOwner{
        feeAddress = _feeAddress;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setFeeAddress(address)",_feeAddress));
    }
    function setLeverageFee(uint64 _buyFee,uint64 _sellFee,uint64 _rebalanceFee)public onlyOwner{
        buyFee = _buyFee;
        sellFee = _sellFee;
        rebalanceFee = _rebalanceFee;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setLeverageFee(uint256,uint256,uint256)",_buyFee,_sellFee,_rebalanceFee));
    }
    function setRebaseTimeLimit(uint32 _rebaseTimeLimit) public onlyOwner{
        rebaseTimeLimit = _rebaseTimeLimit;
        setContractsInfo(rebasePoolID,abi.encodeWithSignature("setTimeLimitation(uint256)",_rebaseTimeLimit));
    }
    function setFPTTimeLimit(uint32 _FPTTimeLimit) public onlyOwner{
        FPTTimeLimit = _FPTTimeLimit;
        setContractsInfo(FPTTokenID,abi.encodeWithSignature("setTimeLimitation(uint256)",_FPTTimeLimit));
    }
    function upgradeFnxProxy(uint256 index,address implementation) public onlyOwner{
        proxyInfo storage curInfo = proxyinfoMap[index];
        curInfo.implementation = implementation;
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(curInfo.proxyList[i]).upgradeTo(implementation);
        }        
    }

    modifier rebalanceEnable(){
        uint64 preIndex = lastRebalance / rebalanceInterval;
        uint64 index = uint64(now) / rebalanceInterval;
        require(index!=preIndex,"This rebalance period is already completed");
        lastRebalance = uint64(now);
        _;
    }
    function leverageSuffix(uint256 leverageRatio) internal pure returns (string memory){
        if (leverageRatio == 0) return "0";
        uint256 integer = leverageRatio*10/1e8;
        uint8 fraction = uint8(integer%10+48);
        integer = integer/10;
        uint8 ten = uint8(integer/10+48);
        uint8 unit = uint8(integer%10+48);
        bytes memory suffix = new bytes(7);
        suffix[0] = bytes1(uint8(95));
        suffix[1] = bytes1(uint8(88));
        uint len = 2;
        if(ten>48){
                suffix[len++] = bytes1(ten);
            }
        suffix[len++] = bytes1(unit);
        if (fraction>48){
            suffix[len++] = bytes1(uint8(46));
            suffix[len++] = bytes1(fraction);
        }
        bytes memory newSuffix = new bytes(len);
        for(uint i=0;i<len;i++){
            newSuffix[i] = suffix[i];
        }
        return string(newSuffix);
    }
}