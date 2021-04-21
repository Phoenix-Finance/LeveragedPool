const BN = require("bn.js");
let eth = "0x0000000000000000000000000000000000000000";

module.exports = {
    feeDecimal : new BN(1e8),
    calDecimal : new BN("1000000000000000000"),
    getDeadLine : function () {
        return Math.floor(Date.now()/1000)+60;
    },
    buyLeverage : async function(eventDecoder,contracts,index,amount,minAmount,account) {
        let rebaseBalancePre = await contracts.rebaseToken[index].balanceOf(account);
        amount = new BN(amount);
        let receipt;
        if(index == 0){
            await contracts.token[index].approve(contracts.leveragePool.address,amount,{from:account});
            receipt = await contracts.leveragePool.buyLeverage(amount,minAmount,this.getDeadLine(),[],{from:account});
        }else{
            if (contracts.tokenAddr[1] == eth){
                receipt = await contracts.leveragePool.buyHedge(amount,minAmount,this.getDeadLine(),[],{from:account,value:amount});
            }else{
                await contracts.token[index].approve(contracts.leveragePool.address,amount,{from:account});
                receipt = await contracts.leveragePool.buyHedge(amount,minAmount,this.getDeadLine(),[],{from:account});
            }
        }
        let events = eventDecoder.decodeTxEvents(receipt);
        let fees = await contracts.leveragePool.getLeverageFee();
        let fee = amount.mul(fees[0]).div(this.feeDecimal)
        let feeEvent = this.findEvent(events,"Redeem",0)
        assert(fee.eq(new BN(feeEvent.amount)),fee.toString(10)+","+feeEvent.amount+ " : Buy leverage fee check failed!");
        let price = await contracts.leveragePool.buyPrices();
        let input = amount.sub(fee);
        let tokenAmount = input.mul(this.calDecimal).div(price[index]);
        let rebaseBalance = await contracts.rebaseToken[index].balanceOf(account);
        console.log("rebaseBalance",rebaseBalancePre.toString(10),rebaseBalance.toString(10));
        rebaseBalance = rebaseBalance.sub(rebaseBalancePre);
        assert(tokenAmount.eq(rebaseBalance),tokenAmount.toString(10)+","+rebaseBalance.toString(10)+ " : rebase token balance check failed!");
        let borrowEvent = this.findEvent(events,"Borrow",0)
        let loan = contracts.info[index][3].sub(this.feeDecimal).mul(tokenAmount).mul(contracts.info[index][4]).div(this.feeDecimal).div(this.calDecimal);
        assert(loan.eq(new BN(borrowEvent.loan)),loan.toString(10)+","+borrowEvent.loan+ " : leverage loan check failed!");
        let rate = await contracts.stakepool[index].interestRate();
        let borrow = loan.mul(this.feeDecimal.sub(rate)).div(this.feeDecimal);
        assert(borrow.eq(new BN(borrowEvent.borrow)),borrow.toString(10)+","+borrowEvent.borrow+ " : leverage borrow check failed!");
        let swap = this.findEvent(events,"Swap",0);
        let swapFrom = borrow.add(amount).sub(fee);
        assert(swapFrom.eq(new BN(swap.fromValue)),swapFrom.toString(10) +","+swap.fromValue+ " : swap from value check failed!");
        let prices = await contracts.oracle.getPrices(contracts.tokenAddr);
        let underlyingPrice = this.getUnderlyingPrice(prices,index);
        let netWorth = underlyingPrice.mul(new BN(swap.toValue)).sub(loan.mul(this.calDecimal)).div(rebaseBalance);
        let getNetworth = await contracts.leveragePool.getTokenNetworths();
        console.log(getNetworth[index].toString(10),netWorth.toString(10));
        //assert(getNetworth[index].eq(netWorth),getNetworth[index].toString(10) +","+netWorth.toString(10)+ " : networth check failed!");
    },
    rebalance : async function(eventDecoder,contracts,index,account) {
        let receipt = await contracts.leveragePool.rebalance({from:account});
    },
    sellLeverage : async function(eventDecoder,contracts,index,amount,minAmount,account) {
        fnxBalance = await contracts.rebaseToken[index].balanceOf(accounts[0]);
        await contracts.rebaseToken[0].approve(contracts.leveragePool.address,fnxBalance);
        let receipt;
        if(index == 0){
            receipt = await lToken.sellLeverage(fnxBalance,this.getDeadLine(),[]);
        }else{
            receipt = await lToken.sellHedge(fnxBalance,this.getDeadLine(),[]);
        }

        let events = eventDecoder.decodeTxEvents(receipt);
        let fees = await contracts.leveragePool.getLeverageFee();
        let fee = amount.mul(fees[0]).div(this.feeDecimal)
        let feeEvent = this.findEvent(events,"Redeem",0)
        assert(fee.eq(new BN(feeEvent.amount)),fee.toString(10)+","+feeEvent.amount+ " : Buy leverage fee check failed!");
        let price = await contracts.leveragePool.buyPrices();
        let input = amount.sub(fee);
        let tokenAmount = input.mul(this.calDecimal).div(price[index]);
        let rebaseBalance = await contracts.rebaseToken[index].balanceOf(account);
        rebaseBalance = rebaseBalance.sub(rebaseBalancePre);
        assert(tokenAmount.eq(rebaseBalance),tokenAmount.toString(10)+","+rebaseBalance.toString(10)+ " : rebase token balance check failed!");
        let borrowEvent = this.findEvent(events,"Borrow",0)
        let leverageRates = await contracts.leveragePool.leverageRates();
        let rebalanceWorth = await contracts.leveragePool.rebalanceWorth();
        let loan = leverageRates[index].sub(this.feeDecimal).mul(tokenAmount).mul(rebalanceWorth[index]).div(this.feeDecimal).div(this.calDecimal);
        assert(loan.eq(new BN(borrowEvent.loan)),loan.toString(10)+","+borrowEvent.loan+ " : leverage loan check failed!");
        let rate = await contracts.stakepool[index].interestRate();
        let borrow = loan.mul(this.feeDecimal.sub(rate)).div(this.feeDecimal);
        assert(borrow.eq(new BN(borrowEvent.borrow)),borrow.toString(10)+","+borrowEvent.borrow+ " : leverage borrow check failed!");
        let swap = this.findEvent(events,"Swap",0);
        let swapFrom = borrow.add(amount).sub(fee);
        assert(swapFrom.eq(new BN(swap.fromValue)),swapFrom.toString(10) +","+swap.fromValue+ " : swap from value check failed!");
        let prices = await contracts.oracle.getPrices(contracts.tokenAddr);
        let underlyingPrice = this.getUnderlyingPrice(prices,index);
        let netWorth = underlyingPrice.mul(new BN(swap.toValue)).sub(loan.mul(this.calDecimal)).div(rebaseBalance);
        let getNetworth = await contracts.leveragePool.getTokenNetworths();
        console.log(getNetworth[index].toString(10),netWorth.toString(10));
    },
    getUnderlyingPrice : function(prices,index){
        return prices[(index+1)%2].mul(this.calDecimal).div(prices[index]);
    },
    findEvent : function(events,name,index) {
        
        for (var i=0;i<events.length;i++){
            if(events[i][0] == name){
                if(index == 0){
                    return events[i][1];
                }else{
                    index--;
                }
            }
        }
    }
}