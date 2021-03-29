pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../modules/SafeMath.sol";
import "../modules/Ownable.sol";
import "../stakePool/stakePoolProxy.sol";
import "../LeveragedPool/leveragePoolProxy.sol";
/**
 * @title FNX period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
 *
 */
contract leveragedFactroy is Ownable{
    using SafeMath for uint256;
    mapping(address=>address) internal stakePoolMap;
    mapping(bytes32=>address payable) internal leveragePoolMap;

    address internal stakePoolImplementation;
    address internal leveragePoolImplementation;
    address internal FPTCoinImplementation;
    address internal rebaseTokenImplementation;
    address internal fnxOracle;
    address internal uniswap;
    address[] internal stakePoolList;
    address payable[] internal leveragePoolList;
    function createLeveragePool(address tokenA,address tokenB,uint256 leverageRatio,
        uint256 leverageRebaseWorth,uint256 hedgeRebaseWorth)external 
        onlyOwner returns (address _stakePoolA,address _stakePoolB,address payable _leveragePool){
            _stakePoolA = getStakePool(tokenA);
            _stakePoolB = getStakePool(tokenB);
        require(_stakePoolA!=address(0) && _stakePoolB!=address(0),"Stake pool is not created");
        bytes32 poolKey = getPairHash(tokenA,tokenB,leverageRatio);
        _leveragePool = leveragePoolMap[poolKey];
        if(_leveragePool == address(0)){
            leveragePoolProxy newPool = new leveragePoolProxy(leveragePoolImplementation);
            newPool.setLeveragePoolInfo(rebaseTokenImplementation,_stakePoolA,_stakePoolB,
                fnxOracle,uniswap,leverageRatio,leverageRebaseWorth,hedgeRebaseWorth);
            _leveragePool = address(newPool);
            leveragePoolMap[poolKey] = _leveragePool;
            leveragePoolList.push(_leveragePool);
        }
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
    function getAllStakePool()external view returns (address[] memory){
        return stakePoolList;
    }
    function getAllLeveragePool()external view returns (address payable[] memory){
        return leveragePoolList;
    }
    function rebalanceAll()external onlyOwner {
        uint256 len = leveragePoolList.length;
        for(uint256 i=0;i<len;i++){
            leveragePoolProxy(leveragePoolList[i]).rebalance();
        }
    }
    function getPairHash(address tokenA,address tokenB,uint256 leverageRatio) internal pure returns (bytes32) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encodePacked(token0, token1,leverageRatio));
    }
    function createStatePool(address token,string memory tokenName,uint64 interestrate)public returns(address){
        address stakePool = stakePoolMap[token];
        if(stakePool == address(0)){
            stakePoolProxy newPool = new stakePoolProxy(stakePoolImplementation,token,
                    FPTCoinImplementation,tokenName,interestrate);
            stakePool = address(newPool);
            stakePoolMap[token] = stakePool;
            stakePoolList.push(stakePool);
        }
        return stakePool;
    }
}