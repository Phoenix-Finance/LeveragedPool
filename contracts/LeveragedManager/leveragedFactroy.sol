pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../modules/SafeMath.sol";
import "../modules/Ownable.sol";
import "../proxy/fnxProxy.sol";
import "../leveragedPool/ILeveragedPool.sol";
import "../stakePool/IStakePool.sol";
import "../ERC20/IERC20.sol";
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
    uint256 public stakePoolVersion;

    address public leveragePoolImpl;
    uint256 public leveragePoolVersion;

    address public FPTCoinImpl;
    uint256 public FPTCoinVersion;

    address public rebaseTokenImpl;
    uint256 public rebaseTokenVersion;

    address public fnxOracle;
    uint64 public buyFee;
    uint64 public sellFee;
    uint64 public rebalanceFee;
    uint64 public interestRate;




    address public uniswap;
    address payable[] public fptCoinList;
    address payable[] public stakePoolList;
    address payable[] public leveragePoolList;

    function createLeveragePool(address tokenA,address tokenB,uint256 leverageRatio,
        uint128 leverageRebaseWorth,uint128 hedgeRebaseWorth)external 
        onlyOwner returns (address payable _leveragePool){
        bytes32 poolKey = getPairHash(tokenA,tokenB,leverageRatio);
        _leveragePool = leveragePoolMap[poolKey];
        if(_leveragePool == address(0)){
            _leveragePool = createLeveragePool_sub(tokenA,tokenB,leverageRatio,leverageRebaseWorth,hedgeRebaseWorth);
            leveragePoolMap[poolKey] = _leveragePool;
            leveragePoolList.push(_leveragePool);
        }
    }
    function createLeveragePool_sub(address tokenA,address tokenB,uint256 leverageRatio,
        uint128 leverageRebaseWorth,uint128 hedgeRebaseWorth)internal returns (address payable _leveragePool){
        address _stakePoolA = getStakePool(tokenA);
        address _stakePoolB = getStakePool(tokenB);
        require(_stakePoolA!=address(0) && _stakePoolB!=address(0),"Stake pool is not created");
        fnxProxy proxy = new fnxProxy(leveragePoolImpl,leveragePoolVersion);
        ILeveragedPool newPool = ILeveragedPool(address(proxy));
        newPool.setLeveragePoolInfo(rebaseTokenImpl,leveragePoolVersion,_stakePoolA,_stakePoolB,
            fnxOracle,uniswap,leverageRatio,leverageRebaseWorth,hedgeRebaseWorth,baseCoinName);
        _leveragePool = address(uint160(address(proxy)));
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
    function rebalanceAll(bool bRebalanceWorth)external onlyOwner {
        uint256 len = leveragePoolList.length;
        for(uint256 i=0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).rebalance(bRebalanceWorth);
        }
    }
    function getPairHash(address tokenA,address tokenB,uint256 leverageRatio) internal pure returns (bytes32) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encodePacked(token0, token1,leverageRatio));
    }
    function createStatePool(address token,uint64 interestrate)public returns(address payable){
        address payable stakePool = stakePoolMap[token];
        if(stakePool == address(0)){
            address fptCoin = createFptCoin(token);
            fnxProxy newPool = new fnxProxy(stakePoolImpl,stakePoolVersion);
            stakePool = address(newPool);
            IStakePool(stakePool).setPoolInfo(fptCoin,token,interestrate);
            stakePoolMap[token] = stakePool;
            stakePoolList.push(stakePool);
            
        }
        return stakePool;
    }
    function createFptCoin(address token)internal returns(address){
        fnxProxy newCoin = new fnxProxy(FPTCoinImpl,FPTCoinVersion);
        fptCoinList.push(address(newCoin));
        string memory tokenName = (token == address(0)) ? strConcat("FPT_","0") : strConcat("FPT_",IERC20(token).symbol());
        IERC20(address(newCoin)).changeTokenName(tokenName,tokenName);
        return address(newCoin);
    }
    function upgradeStakePool(address _stakePoolImpl,uint256 _stakePoolVersion) public onlyOwner{
        uint256 len = stakePoolList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(stakePoolList[i]).upgradeTo(_stakePoolImpl,_stakePoolVersion);
        }
        stakePoolImpl = _stakePoolImpl;
        stakePoolVersion = _stakePoolVersion;
    }
    function upgradeLeveragePool(address _leveragePoolImpl,uint256 _leveragePoolVersion) public onlyOwner{
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(leveragePoolList[i]).upgradeTo(_leveragePoolImpl,_leveragePoolVersion);
        }
        leveragePoolImpl = _leveragePoolImpl;
        leveragePoolVersion = _leveragePoolVersion;
    }
    function upgradeFPTCoin(address _FPTCoinImpl,uint256 _FPTCoinVersion) public onlyOwner{
        uint256 len = fptCoinList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(fptCoinList[i]).upgradeTo(_FPTCoinImpl,_FPTCoinVersion);
        }
        FPTCoinImpl = _FPTCoinImpl;
        FPTCoinVersion = _FPTCoinVersion;
    }
    function upgradeRebaseToken(address _rebaseTokenImpl,uint256 _rebaseTokenVersion) public onlyOwner{
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            (address leverageToken,address hedgeToken) = ILeveragedPool(leveragePoolList[i]).leverageTokens();
            fnxProxy(address(uint160(leverageToken))).upgradeTo(_rebaseTokenImpl,_rebaseTokenVersion);
            fnxProxy(address(uint160(hedgeToken))).upgradeTo(_rebaseTokenImpl,_rebaseTokenVersion);
        }
        rebaseTokenImpl = _rebaseTokenImpl;
        rebaseTokenVersion = _rebaseTokenVersion;
    }
    function setFnxOracle(address _fnxOracle) public onlyOwner{
        fnxOracle = _fnxOracle;
        uint256 len = leveragePoolList.length;
        for(uint256 i=0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).setOracleAddress(_fnxOracle);
        }
    }
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }
}