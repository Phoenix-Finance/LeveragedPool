pragma solidity =0.5.16;
import "../PhoenixModules/ERC20/IERC20.sol";
import "../uniswap/IUniswapV2Pair.sol";
import "../uniswap/IUniswapV2Factory.sol";
contract uniswapOracle {
    address public USDC;
    IUniswapV2Factory public uniswapFactory;
    mapping(address => uint256) internal priceMap;
    constructor(address _usdc,address _uniswapFactory) public {
        USDC = _usdc;
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        priceMap[_usdc] = 1e30;
    } 
    function getErc20Price(address erc20) public view returns (uint256) {
        if (erc20 == USDC){
            return priceMap[USDC];
        }
        address pair = uniswapFactory.getPair(erc20, USDC);
        if (pair == address(0)) {
            return 0;
        }
        IUniswapV2Pair upair = IUniswapV2Pair(pair);
        (uint112 reserve0, uint112 reserve1,) = upair.getReserves();
        if (upair.token0() == USDC){
            return priceMap[USDC]*reserve0/reserve1;
        }else{
            return priceMap[USDC]*reserve1/reserve0;
        }
    }
    function getUniswapPairPrice(address pair) public view returns (uint256) {
        IUniswapV2Pair upair = IUniswapV2Pair(pair);
        (uint112 reserve0, uint112 reserve1,) = upair.getReserves();
        uint256 price = getErc20Price(upair.token0())*reserve0;
        if(price == 0){
            price = getErc20Price(upair.token1())*reserve1;
        }
        if(price == 0){
            return 0;
        }
        uint256 total = upair.totalSupply();
        if (total == 0){
            return 0;
        }
        return price*2/total;
    }
    function getPrice(address token) public view returns (uint256) {
        (bool success, bytes memory returnData) = token.staticcall(abi.encodeWithSignature("getReserves()"));
        if(success){
            return getUniswapPairPrice(token);
        }else{
            uint256 price = getErc20Price(token);
            if(price == 0){
                price = priceMap[token];
            }
            return price;
        }
    }
    function getPrices(address[]memory assets) public view returns (uint256[]memory) {
        uint256 len = assets.length;
        uint256[] memory prices = new uint256[](len);
        for (uint i=0;i<len;i++){
            prices[i] = getPrice(assets[i]);
        }
        return prices;
    }
}