pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../PhoenixModules/modules/SafeMath.sol";
import "./leverageFactoryData.sol";
import "../PhoenixModules/proxy/phxProxy.sol";
import "../LeveragedPool/ILeveragedPool.sol";
import "../stakePool/IStakePool.sol";
import "../PhoenixModules/ERC20/IERC20.sol";
import "../rebaseToken/IRebaseToken.sol";
import "../PhoenixModules/acceleratedMinePool/IAcceleratedMinePool.sol";
import "../PhoenixModules/PPTCoin/IPPTCoin.sol";
import "../PhoenixModules/modules/Address.sol";
/**
 * @title leverage contract factory.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageFactory is leverageFactoryData{
    using SafeMath for uint256;
    using Address for address;
    /**
     * @dev constructor.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }

    function initialize() public{
        versionUpdater.initialize();
        //debug
        PPTTimeLimit = 60;
        rebaseTimeLimit = 60;
    }
    function update() public versionUpdate {
        baseCoinName = "BNB";
        IPPTCoin(0x7B14ba7C2eb0DF20217102CBEb3daceC7182beC4).changeTokenName("PPT_BNB","PPT_BNB",18);
        IRebaseToken(0x89E543f068E1c55ECb0f842a112E6736fE8920FE).changeTokenName("BNB_BULL_X3","BNB_BULL_X3",0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        IRebaseToken(0x2e25891288B647D4d0BE5280fa899E6E47D30F99).changeTokenName("BNB_BEAR_X3","BNB_BEAR_X3",0x0000000000000000000000000000000000000000);
    }
    function setImplementAddress(string memory _baseCoinName,address payable _feeAddress,address rebaseOperator,address _stakePoolImpl,address _leveragePoolImpl,address _PPTCoinImpl,
        address _rebaseTokenImpl,address acceleratedMinePool,address PHXVestingPool,address _phxOracle)public originOnce{
        baseCoinName = _baseCoinName;
        proxyinfoMap[LeveragePoolID].implementation = _leveragePoolImpl;
        proxyinfoMap[stakePoolID].implementation = _stakePoolImpl;
        proxyinfoMap[rebasePoolID].implementation = _rebaseTokenImpl;
        proxyinfoMap[PPTTokenID].implementation = _PPTCoinImpl;
        proxyinfoMap[MinePoolID].implementation = acceleratedMinePool;
        vestingPool = PHXVestingPool;  
        phxOracle = _phxOracle;
        feeAddress = _feeAddress;
        _operators[1] = rebaseOperator;
    }
    function initFactoryInfo(address _swapRouter,address _SwapLib,uint64 _rebalanceInterval,
             uint64 _buyFee, uint64 _sellFee, uint64 _rebalanceFee,uint64 _rebaseThreshold,uint64 _liquidateThreshold,uint64 _interestInflation) public originOnce{
        swapRouter = _swapRouter;
        phxSwapLib = _SwapLib;
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
        onlyOrigin returns (address payable _leveragePool){
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
        _leveragePool = createPhxProxy(LeveragePoolID);
        IStakePool(_stakePoolA).modifyPermission(_leveragePool,0xFFFFFFFFFFFFFFFF);
        IStakePool(_stakePoolB).modifyPermission(_leveragePool,0xFFFFFFFFFFFFFFFF);
        setLeveragePoolInfo_sub(_stakePoolA,_stakePoolB,_leveragePool,tokenA,tokenB,leverageRatio,leverageRebaseWorth);
        emit CreateLeveragePool(_leveragePool,tokenA,tokenB,leverageRatio,leverageRebaseWorth);
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
        newPool.setLeveragePoolInfo(feeAddress,_stakePoolA,_stakePoolB,phxOracle,swapRouter,phxSwapLib,rebaseTokenA,rebaseTokenB,
            uint256(buyFee)+(uint256(sellFee)<<64)+(uint256(rebalanceFee)<<128)+(uint256(leverageRatio)<<192),
            rebaseThreshold +(uint256(liquidateThreshold)<<128),leverageRebaseWorth);
    }
    function createRebaseToken(address leveragePool,address token,string memory name)internal returns(address){
        address payable newToken = createPhxProxy(rebasePoolID);
        IRebaseToken rebaseToken = IRebaseToken(newToken);
        proxyOperator(newToken).setManager(leveragePool);
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
    function setRebalanceInterval(uint64 interval) public onlyOrigin{
        rebalanceInterval = interval;
    }
    function rebalanceAll()external rebalanceEnable onlyOperator(1) {
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
    function createStatePool(address token,uint64 _interestrate)public onlyOrigin returns(address payable){
        address payable stakePool = stakePoolMap[token];
        if(stakePool == address(0)){
            address pptCoin = createPPTCoin(token);
            stakePool = createPhxProxy(stakePoolID);
            IStakePool(stakePool).setPoolInfo(pptCoin,token,_interestrate);
            proxyOperator(pptCoin).setManager(stakePool);
            stakePoolMap[token] = stakePool;
            emit CreateStakePool(stakePool,token,_interestrate);
        }
        return stakePool;
    }
    function createPPTCoin(address token)internal returns(address){
        address payable newCoin = createPhxProxy(PPTTokenID);
        string memory tokenName = (token == address(0)) ? string(abi.encodePacked("PPT_", baseCoinName)):
                 string(abi.encodePacked("PPT_",IERC20(token).symbol()));
        uint8 decimals = (token == address(0)) ? 18 : IERC20(token).decimals();
        IPPTCoin(newCoin).changeTokenName(tokenName,tokenName,decimals);
        IPPTCoin(newCoin).setTimeLimitation(PPTTimeLimit);
        address minePool = createAcceleratedMinePool();
        proxyOperator(minePool).setManager(newCoin);
        IPPTCoin(newCoin).setMinePool(minePool);
        return newCoin;
    }
    function createAcceleratedMinePool()internal returns(address){
        address payable newCoin = createPhxProxy(MinePoolID);
        IAcceleratedMinePool(newCoin).setPHXVestingPool(vestingPool);
        return newCoin;
    }
    function createPhxProxy(uint256 index) internal returns (address payable){
        proxyInfo storage curInfo = proxyinfoMap[index];
        phxProxy newProxy = new phxProxy(curInfo.implementation,getMultiSignatureAddress());
        curInfo.proxyList.push(address(newProxy));
        return address(newProxy);
    }
    function setInterestRate(address token,uint64 rate)public onlyOrigin{
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
    function setPHXVestingPool(address _PHXVestingPool) public onlyOrigin{
        vestingPool = _PHXVestingPool;
        setContractsInfo(MinePoolID,abi.encodeWithSignature("setPHXVestingPool(address)",_PHXVestingPool));
    }
    function setSwapRouterAddress(address _swapRouter)public onlyOrigin{
        swapRouter = _swapRouter;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setSwapRouterAddress(address)",_swapRouter));
    }
    function setSwapLibAddress(address _swapLib)public onlyOrigin{
        phxSwapLib = _swapLib;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setSwapLibAddress(address)",_swapLib));
    }
    function setOracleAddress(address _phxOracle)public onlyOrigin{
        phxOracle = _phxOracle;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setOracleAddress(address)",_phxOracle));
    }
    function setFeeAddress(address payable _feeAddress)public onlyOrigin{
        feeAddress = _feeAddress;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setFeeAddress(address)",_feeAddress));
    }
    function setLeverageFee(uint64 _buyFee,uint64 _sellFee,uint64 _rebalanceFee)public onlyOrigin{
        buyFee = _buyFee;
        sellFee = _sellFee;
        rebalanceFee = _rebalanceFee;
        setContractsInfo(LeveragePoolID,abi.encodeWithSignature("setLeverageFee(uint256,uint256,uint256)",_buyFee,_sellFee,_rebalanceFee));
    }
    function setRebaseTimeLimit(uint32 _rebaseTimeLimit) public onlyOrigin{
        rebaseTimeLimit = _rebaseTimeLimit;
        setContractsInfo(rebasePoolID,abi.encodeWithSignature("setTimeLimitation(uint256)",_rebaseTimeLimit));
    }
    function setPPTTimeLimit(uint32 _PPTTimeLimit) public onlyOrigin{
        PPTTimeLimit = _PPTTimeLimit;
        setContractsInfo(PPTTokenID,abi.encodeWithSignature("setTimeLimitation(uint256)",_PPTTimeLimit));
    }
    function upgradePhxProxy(uint256 index,address implementation) public onlyOrigin{
        proxyInfo storage curInfo = proxyinfoMap[index];
        curInfo.implementation = implementation;
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            phxProxy(curInfo.proxyList[i]).upgradeTo(implementation);
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