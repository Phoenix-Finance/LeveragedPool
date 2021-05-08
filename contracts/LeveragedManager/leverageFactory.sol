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
/**
 * @title FNX period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
 *
 */
contract leverageFactory is leverageFactoryData{
    using SafeMath for uint256;

    constructor() public {

    } 
    function initialize() public{
        versionUpdater.initialize();
        FPTTimeLimit = 30;
        rebaseTimeLimit = 30;
    }
    function update() public onlyOwner versionUpdate {
    }
    function initFactoryInfo(string memory _baseCoinName,address _stakePoolImpl,address _leveragePoolImpl,address _FPTCoinImpl,
        address _rebaseTokenImpl,address _fnxOracle,address _uniswap,address payable _feeAddress,
             uint64 _buyFee, uint64 _sellFee, uint64 _rebalanceFee,uint64 _rebaseThreshold,uint64 _liquidateThreshold,uint64 _interestRate) public onlyOwner{
                baseCoinName = _baseCoinName;
                stakePoolImpl = _stakePoolImpl;
                leveragePoolImpl = _leveragePoolImpl;
                FPTCoinImpl = _FPTCoinImpl;
                rebaseTokenImpl = _rebaseTokenImpl;
                fnxOracle = _fnxOracle;
                uniswap = _uniswap;
                feeAddress = _feeAddress;
                buyFee = _buyFee;
                sellFee = _sellFee;
                rebalanceFee = _rebalanceFee;
                rebaseThreshold = _rebaseThreshold;
                liquidateThreshold = _liquidateThreshold;
                interestAddRate = _interestRate;
             }
    function createLeveragePool(address tokenA,address tokenB,uint64 leverageRatio,
        uint256 leverageRebaseWorth)external 
        onlyOwner returns (address payable _leveragePool){
        bytes32 poolKey = getPairHash(tokenA,tokenB,leverageRatio);
        _leveragePool = leveragePoolMap[poolKey];
        if(_leveragePool == address(0)){
            _leveragePool = createLeveragePool_sub(tokenA,tokenB,leverageRatio,leverageRebaseWorth);
            leveragePoolMap[poolKey] = _leveragePool;
            leveragePoolList.push(_leveragePool);
            
        }
    }
    function createLeveragePool_sub(address tokenA,address tokenB,uint64 leverageRatio,
        uint256 leverageRebaseWorth)internal returns (address payable _leveragePool){
        address _stakePoolA = getStakePool(tokenA);
        address _stakePoolB = getStakePool(tokenB);
        require(_stakePoolA!=address(0) && _stakePoolB!=address(0),"Stake pool is not created");
        fnxProxy newPool = new fnxProxy(leveragePoolImpl);
        _leveragePool = address(uint160(address(newPool)));
        ILeveragedPool pool = ILeveragedPool(_leveragePool);
        IStakePool(_stakePoolA).modifyPermission(_leveragePool,0xFFFFFFFFFFFFFFFF);
        IStakePool(_stakePoolB).modifyPermission(_leveragePool,0xFFFFFFFFFFFFFFFF);
        setLeveragePoolInfo_sub(_stakePoolA,_stakePoolB,_leveragePool,tokenA,tokenB,leverageRatio,leverageRebaseWorth);
        pool.modifyPermission(address(this),0xFFFFFFFFFFFFFFFF);
        
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
        fnxProxy newToken = new fnxProxy(rebaseTokenImpl);
        IRebaseToken leverageToken = IRebaseToken(address(newToken));
        Operator(address(newToken)).setManager(leveragePool);
        leverageToken.changeTokenName(name,name,token);
        leverageToken.setTimeLimitation(rebaseTimeLimit);
        return address(newToken);
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
        return stakePoolList;
    }
    function getAllLeveragePool()external view returns (address payable[] memory){
        return leveragePoolList;
    }
    function setRebalanceInterval(uint64 interval) public onlyOwner{
        rebalanceInterval = interval;
    }
    function rebalanceAll()external rebalanceEnable addressPermissionAllowed(msg.sender,allowRebalance) {
        uint256 len = leveragePoolList.length;
        for(uint256 i=0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).rebalance();
        }
        uint64 addRate = interestAddRate;
        len = stakePoolList.length;
        for(uint256 i=0;i<len;i++){
            IStakePool(stakePoolList[i]).addInterestRate(addRate);
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
            fnxProxy newPool = new fnxProxy(stakePoolImpl);
            stakePool = address(newPool);
            IStakePool(stakePool).setPoolInfo(fptCoin,token,_interestrate);
            Operator(fptCoin).setManager(stakePool);
            stakePoolMap[token] = stakePool;
            stakePoolList.push(stakePool);
            
        }
        return stakePool;
    }
    function createFptCoin(address token)internal returns(address){
        fnxProxy newCoin = new fnxProxy(FPTCoinImpl);
        fptCoinList.push(address(newCoin));
        string memory tokenName = (token == address(0)) ? string(abi.encodePacked("FPT_", baseCoinName)):
                 string(abi.encodePacked("FPT_",IERC20(token).symbol()));
        IERC20(address(newCoin)).changeTokenName(tokenName,tokenName);
        return address(newCoin);
    }
    function upgradeStakePool(address _stakePoolImpl) public onlyOwner{
        uint256 len = stakePoolList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(stakePoolList[i]).upgradeTo(_stakePoolImpl);
        }
        stakePoolImpl = _stakePoolImpl;
    }
    function upgradeLeveragePool(address _leveragePoolImpl) public onlyOwner{
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(leveragePoolList[i]).upgradeTo(_leveragePoolImpl);
        }
        leveragePoolImpl = _leveragePoolImpl;
    }
    function upgradeFPTCoin(address _FPTCoinImpl) public onlyOwner{
        uint256 len = fptCoinList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(fptCoinList[i]).upgradeTo(_FPTCoinImpl);
        }
        FPTCoinImpl = _FPTCoinImpl;
    }
    function setInterestRate(address token,uint64 rate)public onlyOwner{
        address _stakePool = getStakePool(token);
        require(_stakePool != address(0),"stakePool is not found!");
        IStakePool(_stakePool).setInterestRate(rate);
    }
    function setUniswapAddress(address _uniswap)public onlyOwner{
        uniswap = _uniswap;
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).setUniswapAddress(_uniswap);
        }
    }
    function setOracleAddress(address _fnxOracle)public onlyOwner{
        fnxOracle = _fnxOracle;
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).setOracleAddress(_fnxOracle);
        }
    }
    function setFeeAddress(address payable _feeAddress)public onlyOwner{
        feeAddress = _feeAddress;
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).setFeeAddress(_feeAddress);
        }
    }
    function setLeverageFee(uint64 _buyFee,uint64 _sellFee,uint64 _rebalanceFee)public onlyOwner{
        buyFee = _buyFee;
        sellFee = _sellFee;
        rebalanceFee = _rebalanceFee;
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).setLeverageFee(_buyFee,_sellFee,_rebalanceFee);
        }
    }
    function upgradeRebaseToken(address _rebaseTokenImpl) public onlyOwner{
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            (address leverageToken,address hedgeToken) = ILeveragedPool(leveragePoolList[i]).leverageTokens();
            fnxProxy(address(uint160(leverageToken))).upgradeTo(_rebaseTokenImpl);
            fnxProxy(address(uint160(hedgeToken))).upgradeTo(_rebaseTokenImpl);
        }
        rebaseTokenImpl = _rebaseTokenImpl;
    }
    function setFnxOracle(address _fnxOracle) public onlyOwner{
        fnxOracle = _fnxOracle;
        uint256 len = leveragePoolList.length;
        for(uint256 i=0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).setOracleAddress(_fnxOracle);
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