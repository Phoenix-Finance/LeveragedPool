pragma solidity =0.5.16;
import "../interface/IPHXOracle.sol";
import "../ERC20/safeErc20.sol";
import "../uniswap/IUniswapV2Pair.sol";
contract uniswapSync {
    using SafeERC20 for IERC20;
    IPHXOracle internal _oracle;
    constructor(address oracle) public {
        _oracle = IPHXOracle(oracle);
    } 
    function() payable external{

    }
    function redeemAll(address pair)public{
        IUniswapV2Pair uniswapPair = IUniswapV2Pair(pair);
        IERC20 token0 = IERC20(uniswapPair.token0());
        IERC20 token1 = IERC20(uniswapPair.token1());
        token0.safeTransfer(msg.sender,token0.balanceOf(address(this)));
        token1.safeTransfer(msg.sender,token1.balanceOf(address(this)));
    }
    function syncPair(address pair) public {
        IUniswapV2Pair uniswapPair = IUniswapV2Pair(pair);
        IERC20 token0 = IERC20(uniswapPair.token0());
        IERC20 token1 = IERC20(uniswapPair.token1());
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(address(token0));
        assets[1] = uint256(address(token1));
        uint256[]memory prices = oraclegetPrices(assets);
        (uint256 reserve0, uint256 reserve1,) = uniswapPair.getReserves();
        reserve0 = reserve0*prices[0];
        reserve1 = reserve1*prices[1];
        if(reserve0>reserve1){
            reserve1 = (reserve0-reserve1)/prices[1];
            if (reserve1>0){
                uint256 balance = token1.balanceOf(address(this));
                if(balance < reserve1){
                    reserve1 = balance;
                }
                token1.safeTransfer(pair,reserve1);
                uniswapPair.sync();
            }
        }else{
            reserve0 = (reserve1-reserve0)/prices[0];
            if (reserve0>0){
                uint256 balance = token0.balanceOf(address(this));
                if(balance < reserve0){
                    reserve0 = balance;
                }
                token0.safeTransfer(pair,reserve0);
                uniswapPair.sync();
            }
        }
    }
    function oraclegetPrices(uint256[] memory assets) internal view returns (uint256[]memory){
        uint256[] memory prices = _oracle.getPrices(assets);
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
        require(prices[i] >= 100 && prices[i] <= 1e30,"oracle price error");
        }
        return prices;
    }
    function oraclePrice(address asset) internal view returns (uint256){
        uint256 price = _oracle.getPrice(asset);
        require(price >= 100 && price <= 1e30,"oracle price error");
        return price;
    }
}