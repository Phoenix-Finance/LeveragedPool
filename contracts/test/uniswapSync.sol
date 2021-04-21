pragma solidity =0.5.16;
import "../interface/IFNXOracle.sol";
import "../ERC20/safeErc20.sol";
import "../uniswap/IUniswapV2Pair.sol";
contract uniswapSync is ImportOracle {
    using SafeERC20 for IERC20;
    constructor(address oracle) public {
        _oracle = IFNXOracle(oracle);
    } 
    function() payable external{

    }
    function syncPair(address pair) public {
        IUniswapV2Pair uniswapPair = IUniswapV2Pair(pair);
        address token0 = uniswapPair.token0();
        address token1 = uniswapPair.token1();
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(token0);
        assets[1] = uint256(token1);
        uint256[]memory prices = oraclegetPrices(assets);
        (uint256 reserve0, uint256 reserve1,) = uniswapPair.getReserves();
        reserve0 = reserve0*prices[0];
        reserve1 = reserve1*prices[1];
        if(reserve0>reserve1){
            reserve1 = (reserve0-reserve1)/prices[1];
            if (reserve1>0){
                IERC20(token1).safeTransfer(pair,reserve1);
                uniswapPair.sync();
            }
        }else{
            reserve0 = (reserve1-reserve0)/prices[0];
            if (reserve0>0){
                IERC20(token0).safeTransfer(pair,reserve0);
                uniswapPair.sync();
            }
        }
    }
}