
let leverageCheck = require("../check/leverageCheck.js");
let testInfo = require("./testInfo.js");
let eventDecoderClass = require("../contract/eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let FPTCoinAbi = require("../../build/contracts/FPTCoin.json").abi;
let leveragedPoolAbi = require("../../build/contracts/leveragedPool.json").abi;
let stakePoolAbi = require("../../build/contracts/stakePool.json").abi;
const IERC20 = artifacts.require("IERC20");
const BN = require("bn.js");
contract('leveragedPool', function (accounts){
    let beforeInfo;
    before(async () => {
        beforeInfo = await testInfo.before();
        eventDecoder = new eventDecoderClass();
        eventDecoder.initEventsMap([FPTCoinAbi,leveragedPoolAbi,stakePoolAbi]);
    }); 
    it('leveragedPool normal tests', async function (){
        await testToken(beforeInfo.USDC,beforeInfo.WBTC,beforeInfo,accounts,false);
    });
    async function testToken(tokenA,tokenB,beforeInfo,accounts,bFirst){
        let factoryInfo = await testInfo.createFactory(beforeInfo,false,accounts[0]);
        if(bFirst){
            await testInfo.addLiquidity(beforeInfo,factoryInfo,tokenA,tokenB,accounts[0]);
        }
        let pair = await beforeInfo.uniFactory.getPair(tokenA.address,tokenB.address);
        beforeInfo.pair = pair;
        /*
        let tokenaBalance = await tokenA.balanceOf(factoryInfo.uniSync.address);
        let tokenbBalance = await tokenB.balanceOf(factoryInfo.uniSync.address);
        console.log("Underlying balances : ",tokenbBalance.toString(),tokenaBalance.toString())
        */
        let decimalsA = await tokenA.decimals()
        let decimalsB = await tokenB.decimals()
        let base = new BN(10);
        let tokenAmount0 = (new BN(1000)).mul(base.pow(new BN(decimalsA)));
        let tokenAmount1 = (new BN(1000)).mul(base.pow(new BN(decimalsB)));
        let priceA = new BN(1e8);
        priceA = priceA.mul(base.pow(new BN(18-decimalsA)));
        let priceB = new BN(1e11);
        priceB = priceB.mul(base.pow(new BN(18-decimalsB)));
        let assets = [tokenA.address,tokenB.address]
        let prices = [priceA,priceB]
        console.log(priceA.toString(),priceB.toString());
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);
        let contracts = await testInfo.createTokenLeveragePool(tokenA,tokenB,factoryInfo,beforeInfo,accounts[0]);
        let result = await contracts.leveragePool.getLeverageFee();
        console.log("Leverage fee : ",result[0].toString(),result[1].toString(),result[2].toString());
        let netWroth = await contracts.leveragePool.getTokenNetworths();
        console.log("net worth : ",netWroth[0].toString(),netWroth[1].toString());
        await contracts.leveragePool.rebalance();
        await tokenA.approve(contracts.stakepool[0].address,"1000000000000000000000000");
        await contracts.stakepool[0].stake("1000000000000000000000000");
        await tokenB.approve(contracts.stakepool[1].address,"1000000000000000000000000");
        await contracts.stakepool[1].stake("1000000000000000000000000");
        await contracts.leveragePool.rebalance();
        await leverageCheck.buyLeverage(eventDecoder,contracts,0,tokenAmount0,0,accounts[0]);
        let aBalance = await tokenA.balanceOf(contracts.leveragePool.address);
        let bBalance = await tokenB.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",bBalance.toString(),aBalance.toString())
        await leverageCheck.buyLeverage(eventDecoder,contracts,0,tokenAmount0,0,accounts[0]);
        aBalance = await tokenA.balanceOf(contracts.leveragePool.address);
        bBalance = await tokenB.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",bBalance.toString(),aBalance.toString())
        await leverageCheck.buyLeverage(eventDecoder,contracts,1,tokenAmount1,0,accounts[0]);
        aBalance = await tokenA.balanceOf(contracts.leveragePool.address);
        bBalance = await tokenB.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",bBalance.toString(),aBalance.toString())
        await leverageCheck.buyLeverage(eventDecoder,contracts,1,tokenAmount1,0,accounts[0]); 
        aBalance = await tokenA.balanceOf(contracts.leveragePool.address);
        bBalance = await tokenB.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",bBalance.toString(),aBalance.toString())
        prices = [priceA,priceB.sub(priceB.div(new BN(10)))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);       
        let receipt = await contracts.leveragePool.rebalance();
        let price = await contracts.leveragePool.buyPrices();
        console.log("buy prices : ",price[0].toString(),price[1].toString())
        //let events = eventDecoder.decodeTxEvents(receipt);
        //console.log(events);
        let getNetworth = await contracts.leveragePool.getTokenNetworths();
        console.log("Networth : ",getNetworth[0].toString(10),getNetworth[1].toString(10));
        getNetworth = await contracts.leveragePool.getLeverageRebase()
        console.log(getNetworth[0],getNetworth[1]);
        getNetworth = await contracts.leveragePool.getEnableLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        prices = [priceA,priceB.sub(priceB.div(new BN(5)))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        receipt = await contracts.leveragePool.rebalance();
        price = await contracts.leveragePool.buyPrices();
        console.log("buy prices : ",price[0].toString(),price[1].toString())
        //events = eventDecoder.decodeTxEvents(receipt);
        //console.log(events);
        getNetworth = await contracts.leveragePool.getTokenNetworths();
        console.log("Networth : ",getNetworth[0].toString(10),getNetworth[1].toString(10));
        getNetworth = await contracts.leveragePool.getLeverageRebase()
        console.log(getNetworth[0],getNetworth[1]);
        getNetworth = await contracts.leveragePool.getEnableLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        receipt = await contracts.leveragePool.rebalance();
        price = await contracts.leveragePool.buyPrices();
        console.log("buy prices : ",price[0].toString(),price[1].toString())
        getNetworth = await contracts.leveragePool.getTokenNetworths();
        console.log("Networth : ",getNetworth[0].toString(10),getNetworth[1].toString(10));
        getNetworth = await contracts.leveragePool.getLeverageRebase()
        console.log(getNetworth[0],getNetworth[1]);
        getNetworth = await contracts.leveragePool.getEnableLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        prices = [priceA,priceB.sub(priceB.div(new BN(2)))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        getNetworth = await contracts.leveragePool.getEnableLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        if(getNetworth[0]){
            await contracts.leveragePool.liquidateLeverage();
            let rebaseBalance = await contracts.rebaseToken[0].balanceOf(accounts[0]);
            console.log(rebaseBalance.toString());
        }
        if(getNetworth[1]){
            await contracts.leveragePool.liquidateHedge();
            let rebaseBalance = await contracts.rebaseToken[1].balanceOf(accounts[0]);
            console.log(rebaseBalance.toString());
        }
        aBalance = await tokenA.balanceOf(contracts.leveragePool.address);
        bBalance = await tokenB.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",bBalance.toString(),aBalance.toString())
        fnxBalance = await contracts.rebaseToken[1].balanceOf(accounts[0]);
        console.log("rebase Balance : ",fnxBalance.toString());
        await contracts.rebaseToken[1].approve(lToken.address,fnxBalance);
        await lToken.sellHedge(fnxBalance,1000,leverageCheck.getDeadLine(),"0x");
    }
});