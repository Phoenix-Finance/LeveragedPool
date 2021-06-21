pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../modules/SafeMath.sol";
import "./leverageDashboardData.sol";
import "../LeveragedPool/ILeveragedPool.sol";
import "../stakePool/IStakePool.sol";
/**
 * @title leverage contract Router.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageDashboard is leverageDashboardData{
    using SafeMath for uint256;
    function setLeverageFactory(address leverageFactory) external OwnerOrOrigin{
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
        (,address stakePool,,uint256 leverageRate,uint256 rebalanceWorth) = pool.getLeverageInfo();
        return getPurchasableAmount_sub(stakePool,leverageRate,rebalanceWorth);
    }
    function getHedgePurchasableAmount(address leveragedPool) public view returns(uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (,address stakePool,,uint256 leverageRate,uint256 rebalanceWorth) = pool.getHedgeInfo();
        return getPurchasableAmount_sub(stakePool,leverageRate,rebalanceWorth);
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
    function getPurchasableAmount_sub(address stakePool, uint256 leverageRate,uint256 rebalanceWorth) 
        internal view returns(uint256){
        uint256 _loan = IStakePool(stakePool).poolBalance();
        uint256 amountLimit = _loan.mul(feeDecimal)/(leverageRate-feeDecimal)/rebalanceWorth;
        return amountLimit;
    }
}