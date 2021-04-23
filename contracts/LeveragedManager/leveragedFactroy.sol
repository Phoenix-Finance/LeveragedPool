pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../modules/SafeMath.sol";
import "../modules/Managerable.sol";
import "../modules/Ownable.sol";
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
contract leveragedFactroy is Ownable{
    using SafeMath for uint256;
    mapping(address=>address payable) public stakePoolMap;
    mapping(bytes32=>address payable) public leveragePoolMap;

    string public baseCoinName;

    address public stakePoolImpl;

    address public leveragePoolImpl;

    address public FPTCoinImpl;

    address public rebaseTokenImpl;

    address public fnxOracle;
    address public uniswap;

    address payable public feeAddress;

    //feeDecimals = 8; 
    uint64 public buyFee;
    uint64 public sellFee;
    uint64 public rebalanceFee;
    uint64 public interestRate;
    uint64 public rebaseThreshold;
    uint64 public liquidateThreshold;


    address payable[] public fptCoinList;
    address payable[] public stakePoolList;
    address payable[] public leveragePoolList;
    constructor() public {

    } 
    function initFactroryInfo(string memory _baseCoinName,address _stakePoolImpl,address _leveragePoolImpl,address _FPTCoinImpl,
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
                interestRate = _interestRate;
             }
    function createLeveragePool(address tokenA,address tokenB,uint64 leverageRatio,
        uint128 leverageRebaseWorth,uint128 hedgeRebaseWorth)external 
        onlyOwner returns (address payable _leveragePool){
        bytes32 poolKey = getPairHash(tokenA,tokenB,leverageRatio);
        _leveragePool = leveragePoolMap[poolKey];
        if(_leveragePool == address(0)){
            _leveragePool = createLeveragePool_sub(tokenA,tokenB);
            leveragePoolMap[poolKey] = _leveragePool;
            leveragePoolList.push(_leveragePool);
            setLeveragePoolInfo_sub(_leveragePool,tokenA,tokenB,leverageRatio,leverageRebaseWorth,hedgeRebaseWorth);
        }
    }
    function createLeveragePool_sub(address _stakePoolA,address _stakePoolB)internal returns (address payable _leveragePool){
        _stakePoolA = getStakePool(_stakePoolA);
        _stakePoolB = getStakePool(_stakePoolB);
        require(_stakePoolA!=address(0) && _stakePoolB!=address(0),"Stake pool is not created");
        fnxProxy newPool = new fnxProxy(leveragePoolImpl);
        _leveragePool = address(uint160(address(newPool)));
        ILeveragedPool pool = ILeveragedPool(_leveragePool);
        pool.setLeveragePoolAddress(feeAddress,_stakePoolA,_stakePoolB,fnxOracle,uniswap);
        IStakePool(_stakePoolA).modifyPermission(_leveragePool,0xFFFFFFFFFFFFFFFF);
        IStakePool(_stakePoolB).modifyPermission(_leveragePool,0xFFFFFFFFFFFFFFFF);
    }
    function setLeveragePoolInfo_sub(address payable _leveragePool,address tokenA,address tokenB,uint64 leverageRatio,
        uint128 leverageRebaseWorth,uint128 hedgeRebaseWorth) internal {
        string memory token0 = (tokenA == address(0)) ? baseCoinName : IERC20(tokenA).symbol();
        string memory token1 = (tokenB == address(0)) ? baseCoinName : IERC20(tokenB).symbol();
        string memory suffix = leverageSuffix(leverageRatio);

        string memory leverageName = string(abi.encodePacked("LPT_",token0,uint8(95),token1,suffix));
        string memory hedgeName = string(abi.encodePacked("HPT_",token1,uint8(95),token0,suffix));
        ILeveragedPool newPool = ILeveragedPool(_leveragePool);
        newPool.setLeveragePoolInfo(createRebaseToken(_leveragePool,tokenA,leverageName),
            createRebaseToken(_leveragePool,tokenB,hedgeName),uint256(buyFee)+(uint256(sellFee)<<64)+(uint256(rebalanceFee)<<128)+(uint256(leverageRatio)<<192),
            rebaseThreshold +(uint256(liquidateThreshold)<<128),leverageRebaseWorth+(uint256(hedgeRebaseWorth)<<128));
    }
    function createRebaseToken(address leveragePool,address token,string memory name)internal returns(address){
        fnxProxy newToken = new fnxProxy(rebaseTokenImpl);
        IRebaseToken leverageToken = IRebaseToken(address(newToken));
        leverageToken.modifyPermission(leveragePool,0xFFFFFFFFFFFFFFFF);
        leverageToken.changeTokenName(name,name,token);
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
    function rebalanceAll()external onlyOwner {
        uint256 len = leveragePoolList.length;
        for(uint256 i=0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).rebalance();
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
            Managerable(fptCoin).setManager(stakePool);
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