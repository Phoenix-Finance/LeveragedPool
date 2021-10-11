pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../PhoenixModules/modules/SafeMath.sol";
import "./leverageDashboardData.sol";
import "../LeveragedPool/ILeveragedPool.sol";
import "../stakePool/IStakePool.sol";
import "../uniswap/IUniswapV2Router02.sol";
/**
 * @title leverage contract Router.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageDashboard is leverageDashboardData{
    using SafeMath for uint256;
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }

    function setLeverageFactory(address leverageFactory) external originOnce{
        factory = ILeverageFactory(leverageFactory);
    }
    function buyPricesUSD(address leveragedPool) public view returns(uint256,uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        (uint256 leveragePrice,uint256 hedgePrice) = pool.buyPrices();
        return (leveragePrice*prices[0],hedgePrice*prices[1]);
    }
    function getLeveragePurchasableAmount(address leveragedPool) public view returns(uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (,address stakePool,,uint256 leverageRate,) = pool.getLeverageInfo();
        (uint256 leveragePrice,) = pool.buyPrices();
        return getPurchasableAmount_sub(stakePool,leverageRate,leveragePrice);
    }
    function getHedgePurchasableAmount(address leveragedPool) public view returns(uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (,address stakePool,,uint256 leverageRate,) = pool.getHedgeInfo();
        (,uint256 hedgePrice) = pool.buyPrices();
        return getPurchasableAmount_sub(stakePool,leverageRate,hedgePrice);
    }
    function getLeveragePurchasableUSD(address leveragedPool) external view returns(uint256){
        uint256 amount = getLeveragePurchasableAmount(leveragedPool);
        (uint256 leveragePrice,) = buyPricesUSD(leveragedPool);
        return amount.mul(leveragePrice);
    }
    function getHedgePurchasableUSD(address leveragedPool) external view returns(uint256){
        uint256 amount = getHedgePurchasableAmount(leveragedPool);
        (,uint256 hedgePrice) = buyPricesUSD(leveragedPool);
        return amount.mul(hedgePrice);
    }
    function getPurchasableAmount_sub(address stakePool, uint256 leverageRate,uint256 price) 
        internal view returns(uint256){
        uint256 _loan = IStakePool(stakePool).poolBalance();
        uint256 amountLimit = _loan.mul(feeDecimal)/(leverageRate-feeDecimal);
        return amountLimit.mul(calDecimal)/price;
    }
    function buyLeverageAmountsOut(address leveragedPool,address token, uint256 amount)external view returns(uint256){
        uint256 amountLimit = getLeveragePurchasableAmount(leveragedPool);
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        (uint256 leveragePrice,) = pool.buyPrices(); 
        (address token0,,,,) = pool.getLeverageInfo();
        (address token1,,,,) = pool.getHedgeInfo();
        if (token == token0){
            amount = amount.mul(calDecimal)/leveragePrice;
        }else if(token == token1){
            amount = amount.mulPrice(prices,0)/leveragePrice;
        }else{
            require(false,"Input token is illegal");
        }
        require(amount<=amountLimit,"Stake pool loan is insufficient!");
        return amount;
    }
    function buyHedgeAmountsOut(address leveragedPool,address token, uint256 amount)external view returns(uint256){
        uint256 amountLimit = getHedgePurchasableAmount(leveragedPool);
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        (,uint256 hedgePrice) = pool.buyPrices(); 
        (address token0,,,,) = pool.getLeverageInfo();
        (address token1,,,,) = pool.getHedgeInfo();

        if (token == token1){
            amount = amount.mul(calDecimal)/hedgePrice;
        }else if(token == token0){
            amount = amount.mulPrice(prices,1)/hedgePrice;
        }else{
            require(false,"Input token is illegal");
        }
        require(amount<=amountLimit,"Stake pool loan is insufficient!");
        return amount;
    }
    function sellLeverageAmountsOut(address leveragedPool, uint256 amount,address outToken)external view returns(uint256,uint256,uint256,uint256){ 
        return sellAmountsOut(leveragedPool,0,amount,outToken);
    }
    function sellHedgeAmountsOut(address leveragedPool, uint256 amount,address outToken)external view returns(uint256,uint256,uint256,uint256){ 
        return sellAmountsOut(leveragedPool,1,amount,outToken);
    }
    function sellAmountsOut(address leveragedPool,uint8 id, uint256 amount,address outToken)internal view returns(uint256,uint256,uint256,uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (address token0,address token1,uint256 userLoan,uint256 userPayback) = getPoolInfo(pool,id,amount);
        if (outToken == token1){
            return getSellAmountsIn(pool,id,token0,token1,userLoan,userPayback);
        }else{
            return getSellAmountsOut(pool,id,token0,token1,userLoan,userPayback);
        }
    }
    function getPoolInfo(ILeveragedPool pool,uint8 id, uint256 amount)internal view returns(address,address,uint256,uint256){
                address token0;address token1;
        uint256 networth;uint256 leverageRate;uint256 rebalanceWorth;
        if (id == 0){
            (token0,,,leverageRate,rebalanceWorth) = pool.getLeverageInfo();
            (token1,,,,) = pool.getHedgeInfo();
            (networth,) = pool.getTokenNetworths();
        }else{
            (token0,,,leverageRate,rebalanceWorth) = pool.getHedgeInfo();
            (token1,,,,) = pool.getLeverageInfo();
            (,networth) = pool.getTokenNetworths();
        }
        uint256 userLoan = (amount.mul(rebalanceWorth)/feeDecimal).mul(leverageRate-feeDecimal);
        uint256 userPayback =  amount.mul(networth);
        return (token0,token1,userLoan,userPayback);
    }
    function getSellAmountsIn(ILeveragedPool pool,uint8 id,address token0,address token1,uint256 userLoan,uint256 userPayback) internal view
        returns(uint256,uint256,uint256,uint256) {
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        uint256 sellAmount = userLoan.divPrice(prices,id);
        uint256 amountOut = userLoan/calDecimal;
        uint256 amountIn = getSwapAmountsIn(pool,token0,token1,amountOut);
        uint256 swapRate = amountIn.mul(feeDecimal)/sellAmount;
        sellAmount = userLoan.add(userPayback).divPrice(prices,id);
        userPayback = sellAmount - amountIn;
        uint256 sellFee = pool.sellFee();
        userPayback = userPayback.mul(feeDecimal-sellFee)/feeDecimal; 
        return (userPayback,amountIn,amountOut,swapRate);
    }
    function getSellAmountsOut(ILeveragedPool pool,uint8 id,address token0,address token1,uint256 userLoan,uint256 userPayback) internal view
        returns(uint256,uint256,uint256,uint256) {
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        uint256 amountIn = userLoan.add(userPayback).divPrice(prices,id);
        uint256 amountOut = getSwapAmountsOut(pool,token0,token1,amountIn);
        uint256 swapRate = amountOut.mul(feeDecimal)/(userLoan.add(userPayback)/calDecimal);
        userPayback = amountOut-userLoan/calDecimal;
        uint256 sellFee = pool.sellFee();
        userPayback = userPayback.mul(feeDecimal-sellFee)/feeDecimal; 
        return (userPayback,amountIn,amountOut,swapRate);
    }
    function getSwapAmountsIn(ILeveragedPool pool,address token0,address token1,uint256 amountOut)internal view returns (uint256){
        address router = pool.swapRouter();
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(router);
        address[] memory path = getSwapPath(pool,router,token0,token1);
        uint[] memory amounts = IUniswap.getAmountsIn(amountOut, path);
        return amounts[0];
    }
    function getSwapAmountsOut(ILeveragedPool pool,address token0,address token1,uint256 amountIn)internal view returns (uint256){
        address router = pool.swapRouter();
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(router);
        address[] memory path = getSwapPath(pool,router,token0,token1);
        uint[] memory amounts = IUniswap.getAmountsOut(amountIn, path);
        return amounts[amounts.length-1];
    }
    function getSwapPath(ILeveragedPool pool,address swapRouter,address token0,address token1) internal view returns (address[] memory path){
        path = pool.getSwapRoutingPath(token0,token1);
        if(path.length>0){
            return path;
        }
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        path = new address[](2);
        path[0] = token0 == address(0) ? IUniswap.WETH() : token0;
        path[1] = token1 == address(0) ? IUniswap.WETH() : token1;
    }
}