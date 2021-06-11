
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
        await testETH(beforeInfo.USDC,beforeInfo,accounts,false);
    });
    return;
    it('leveragedPool normal tests 2', async function (){
        await testETH2(beforeInfo.USDC,beforeInfo.WBTC,beforeInfo,accounts,false);
        await testETH2(beforeInfo.USDC,beforeInfo.WETH,beforeInfo,accounts,false);
    })
    async function logInfo(tokenA,contracts){
        console.log("===============================================================");
        let aBalance = await tokenA.balanceOf(contracts.leveragePool.address);
        let bBalance = await tokenB.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",aBalance.toString(),bBalance.toString());
        aBalance = await contracts.stakepool[0].loan(contracts.leveragePool.address);
        bBalance = await contracts.stakepool[1].loan(contracts.leveragePool.address);
        console.log("loan : ",aBalance.toString(),bBalance.toString());
        aBalance = await contracts.rebaseToken[0].totalSupply();
        bBalance = await contracts.rebaseToken[1].totalSupply();
        console.log("totalSupply : ",aBalance.toString(),bBalance.toString());
        let info0 = await contracts.leveragePool.getLeverageInfo();
        let info1 = await contracts.leveragePool.getHedgeInfo();
        console.log("rebaseWorth : ",info0[4].toString(),info1[4].toString());
        aBalance = await contracts.leveragePool.rebalancePrices(0);
        bBalance = await contracts.leveragePool.rebalancePrices(1);
        console.log("rebasePrices : ",aBalance.toString(),bBalance.toString());
        aBalance = await contracts.oracle.getPrice(tokenA.address);
        bBalance = await contracts.oracle.getPrice(tokenB.address);
        console.log("current Prices : ",aBalance.toString(),bBalance.toString());        
        let price = await contracts.leveragePool.buyPrices();
        console.log("buy prices : ",price[0].toString(),price[1].toString())
        let netWroth = await contracts.leveragePool.getTokenNetworths();
        console.log("net worth : ",netWroth[0].toString(),netWroth[1].toString());
        netWroth = await contracts.leveragePool.getTotalworths();
        console.log("total worth : ",netWroth[0].toString(),netWroth[1].toString());

        console.log("===============================================================");
    }
    async function testETH(tokenA,beforeInfo,accounts,bFirst){
        let factoryInfo = await testInfo.createFactory(beforeInfo,false,accounts[0],accounts);
        if(bFirst){
            await testInfo.addLiquidityETH(beforeInfo,factoryInfo,tokenA,accounts[0]);
        }
        let weth = await beforeInfo.routerV2.WETH();
        let pair = await beforeInfo.uniFactory.getPair(tokenA.address,weth);
        beforeInfo.pair = pair;
        
        /*
        let tokenaBalance = await tokenA.balanceOf(factoryInfo.uniSync.address);
        let tokenbBalance = await tokenB.balanceOf(factoryInfo.uniSync.address);
        console.log("Underlying balances : ",tokenbBalance.toString(),tokenaBalance.toString())
        */
        let decimalsA = await tokenA.decimals()
        let decimalsB = 18
        let base = new BN(10);
        let tokenAmount0 = (new BN(10)).mul(base.pow(new BN(decimalsA)));
        let tokenAmount1 = (new BN(10)).mul(base.pow(new BN(decimalsB)));
        let priceA = new BN(1e8);
        priceA = priceA.mul(base.pow(new BN(18-decimalsA)));
        let priceB = new BN(6e12);
        priceB = priceB.mul(base.pow(new BN(18-decimalsB)));
        let assets = [tokenA.address,eth,weth]
        let prices = [priceA,priceB,priceB]
        console.log(priceA.toString(),priceB.toString());
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);
        let contracts = await testInfo.createLeveragePool(tokenA,factoryInfo,beforeInfo,accounts[0],accounts);
        let netWroth = await contracts.leveragePool.getTokenNetworths();
        console.log("net worth : ",netWroth[0].toString(),netWroth[1].toString());
        receipt = await factoryInfo.factory.rebalanceAll();
//        events = eventDecoder.decodeTxEvents(receipt);
//        console.log(events);
        await tokenA.approve(contracts.stakepool[0].address,"1000000000000000000000000");
        await contracts.stakepool[0].stake("1000000000000000000000000");
        await contracts.stakepool[1].stake("1000000000000000000000000",{value:"1000000000000000000000000"});
        await factoryInfo.factory.rebalanceAll();
        await leverageCheck.buyLeverage(eventDecoder,contracts,0,tokenAmount0,0,accounts[0]);
        return;
        await logInfo(tokenA,tokenB,contracts);
        await leverageCheck.buyLeverage(eventDecoder,contracts,0,tokenAmount0,0,accounts[0]);
        await logInfo(tokenA,tokenB,contracts);
        prices = [priceA,priceB.sub(priceB.divn(20)),priceB.sub(priceB.divn(20))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        await leverageCheck.buyLeverage(eventDecoder,contracts,1,tokenAmount1,0,accounts[0]);
        await logInfo(tokenA,tokenB,contracts);
        await leverageCheck.buyLeverage(eventDecoder,contracts,1,tokenAmount1,0,accounts[0]); 
        await logInfo(tokenA,tokenB,contracts);
        prices = [priceA,priceB.add(priceB.divn(8)),priceB.add(priceB.divn(8))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);       
        await logInfo(tokenA,tokenB,contracts);
        fnxBalance = await contracts.rebaseToken[0].balanceOf(accounts[0]);
        fnxBalance = fnxBalance.divn(10)
        console.log("rebase Balance : ",fnxBalance.toString());
        await contracts.rebaseToken[0].approve(lToken.address,fnxBalance);
        await lToken.sellLeverage(fnxBalance,10,leverageCheck.getDeadLine(),"0x");
        receipt = await factoryInfo.factory.rebalanceAll();
        events = eventDecoder.decodeTxEvents(receipt);
        console.log(events);
        await logInfo(tokenA,tokenB,contracts);
        prices = [priceA,priceB.sub(priceB.divn(5)),priceB.sub(priceB.divn(5))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        await logInfo(tokenA,tokenB,contracts);
        await factoryInfo.factory.rebalanceAll();
        await logInfo(tokenA,tokenB,contracts);
        await factoryInfo.factory.rebalanceAll();
        await logInfo(tokenA,tokenB,contracts);
        prices = [priceA,priceB.sub(priceB.divn(2)),priceB.sub(priceB.divn(2))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        //await logInfo(tokenA,tokenB,contracts);
        getNetworth = await contracts.leveragePool.getEnableRebalanceAndLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        if(getNetworth[0] || getNetworth[1]){
            await contracts.leveragePool.rebalanceAndLiquidate();
            let rebaseBalance = await contracts.rebaseToken[0].balanceOf(accounts[0]);
            console.log(rebaseBalance.toString());
            rebaseBalance = await contracts.rebaseToken[1].balanceOf(accounts[0]);
            console.log(rebaseBalance.toString());
        }
        aBalance = await tokenA.balanceOf(contracts.leveragePool.address);
        bBalance = await tokenB.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",bBalance.toString(),aBalance.toString())
        fnxBalance = await contracts.rebaseToken[1].balanceOf(accounts[0]);
        console.log("rebase Balance : ",fnxBalance.toString());
        await contracts.rebaseToken[1].approve(lToken.address,fnxBalance);
        await lToken.sellHedge(fnxBalance,10,leverageCheck.getDeadLine(),"0x");
    }
    async function testToken2(tokenA,tokenB,beforeInfo,accounts,bFirst){
        let factoryInfo = await testInfo.createFactory(beforeInfo,false,accounts[0],accounts);
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
        let priceB = new BN(6e12);
        priceB = priceB.mul(base.pow(new BN(18-decimalsB)));
        let assets = [tokenA.address,tokenB.address]
        let prices = [priceA,priceB]
        console.log(priceA.toString(),priceB.toString());
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);
        let contracts = await testInfo.createTokenLeveragePool(tokenA,tokenB,factoryInfo,beforeInfo,accounts[0],accounts);
        let netWroth = await contracts.leveragePool.getTokenNetworths();
        console.log("net worth : ",netWroth[0].toString(),netWroth[1].toString());
        await factoryInfo.factory.rebalanceAll();
        await tokenA.approve(contracts.stakepool[0].address,"1000000000000000000000000");
        await contracts.stakepool[0].stake("1000000000000000000000000");
        await tokenB.approve(contracts.stakepool[1].address,"1000000000000000000000000");
        await contracts.stakepool[1].stake("1000000000000000000000000");
        await factoryInfo.factory.rebalanceAll();

        await leverageCheck.buyLeverage2(eventDecoder,contracts,0,tokenAmount1,0,accounts[0]);
        await logInfo(tokenA,tokenB,contracts);
        await leverageCheck.buyLeverage2(eventDecoder,contracts,0,tokenAmount1,0,accounts[0]);
        await logInfo(tokenA,tokenB,contracts);
        prices = [priceA,priceB.sub(priceB.divn(20))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        await leverageCheck.buyLeverage2(eventDecoder,contracts,1,tokenAmount0,0,accounts[0]);

        await logInfo(tokenA,tokenB,contracts);
        await leverageCheck.buyLeverage2(eventDecoder,contracts,1,tokenAmount0,0,accounts[0]); 
        await logInfo(tokenA,tokenB,contracts);
        prices = [priceA,priceB.sub(priceB.div(new BN(10)))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);       
        await logInfo(tokenA,tokenB,contracts);
        fnxBalance = await contracts.rebaseToken[0].balanceOf(accounts[0]);
        fnxBalance = fnxBalance.divn(10)
        console.log("rebase Balance : ",fnxBalance.toString());
        await contracts.rebaseToken[0].approve(lToken.address,fnxBalance);
        receipt = await lToken.sellLeverage2(fnxBalance,10,leverageCheck.getDeadLine(),"0x");
        await factoryInfo.factory.rebalanceAll();
        await logInfo(tokenA,tokenB,contracts);
        prices = [priceA,priceB.sub(priceB.divn(5))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        await logInfo(tokenA,tokenB,contracts);
        await factoryInfo.factory.rebalanceAll();
        await logInfo(tokenA,tokenB,contracts);
        await factoryInfo.factory.rebalanceAll();
        await logInfo(tokenA,tokenB,contracts);
        prices = [priceA,priceB.sub(priceB.divn(2))]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        //await logInfo(tokenA,tokenB,contracts);
        getNetworth = await contracts.leveragePool.getEnableRebalanceAndLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        if(getNetworth[0] || getNetworth[1]){
            await contracts.leveragePool.rebalanceAndLiquidate();
            let rebaseBalance = await contracts.rebaseToken[0].balanceOf(accounts[0]);
            console.log(rebaseBalance.toString());
            rebaseBalance = await contracts.rebaseToken[1].balanceOf(accounts[0]);
            console.log(rebaseBalance.toString());
        }
        aBalance = await tokenA.balanceOf(contracts.leveragePool.address);
        bBalance = await tokenB.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",bBalance.toString(),aBalance.toString())
        fnxBalance = await contracts.rebaseToken[1].balanceOf(accounts[0]);
        console.log("rebase Balance : ",fnxBalance.toString());
        await contracts.rebaseToken[1].approve(lToken.address,fnxBalance);
        await lToken.sellHedge2(fnxBalance,10,leverageCheck.getDeadLine(),"0x");
    }
});