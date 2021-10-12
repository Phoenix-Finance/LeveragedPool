
let leverageCheck = require("../check/leverageCheck.js");
let testInfo = require("./testInfo.js");
let eventDecoderClass = require("../contract/eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let FPTCoinAbi = require("../../build/contracts/FPTCoin.json").abi;
let leveragedPoolAbi = require("../../build/contracts/leveragedPool.json").abi;
let stakePoolAbi = require("../../build/contracts/stakePool.json").abi;
const leverageDashboard = artifacts.require("leverageDashboard");
const phxProxy = artifacts.require("phxProxy");
const IERC20 = artifacts.require("IERC20");
const BN = require("bn.js");
contract('leverageDashBoard', function (accounts){
    let beforeInfo;
    before(async () => {
        beforeInfo = await testInfo.before();
        eventDecoder = new eventDecoderClass();
        eventDecoder.initEventsMap([FPTCoinAbi,leveragedPoolAbi,stakePoolAbi]);
    }); 
    it('leverageDashBoard normal tests', async function (){

        await testToken(beforeInfo.USDC,beforeInfo.WBTC,beforeInfo,accounts);
    });
    async function testToken(tokenA,tokenB,beforeInfo,accounts){
        let factoryInfo = await testInfo.createFactory(beforeInfo,false,accounts[0],accounts);
        let pair = await beforeInfo.uniFactory.getPair(tokenA.address,tokenB.address);
        if(pair == eth){
            await testInfo.addLiquidity(beforeInfo,factoryInfo,tokenA,tokenB,accounts[0]);
            pair = await beforeInfo.uniFactory.getPair(tokenA.address,tokenB.address);
        }
        beforeInfo.pair = pair;
        

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
        let dashBoard = await leverageDashboard.new(factoryInfo.multiSignature.address);
        let dashProxy = await phxProxy.new(dashBoard.address,factoryInfo.multiSignature.address);
        dashBoard = await leverageDashboard.at(dashProxy.address)
        await dashBoard.setLeverageFactory(factoryInfo.factory.address)
        await tokenA.approve(contracts.stakepool[0].address,"1000000000000000000000000");
        await contracts.stakepool[0].stake("1000000000000000000000000");
        await tokenB.approve(contracts.stakepool[1].address,"1000000000000000000000000");
        await contracts.stakepool[1].stake("1000000000000000000000000");
        let result = await dashBoard.buyPricesUSD(contracts.leveragePool.address);
        console.log("buyPricesUSD",result[0].toString(),result[1].toString())
        result = await dashBoard.getLeveragePurchasableAmount(contracts.leveragePool.address);
        console.log("getLeveragePurchasableAmount",result.toString())

        result = await dashBoard.getHedgePurchasableAmount(contracts.leveragePool.address);
        console.log("getHedgePurchasableAmount",result.toString())
        result = await dashBoard.getLeveragePurchasableUSD(contracts.leveragePool.address);
        console.log("getLeveragePurchasableUSD",result.toString())
        result = await dashBoard.getHedgePurchasableUSD(contracts.leveragePool.address);
        console.log("getHedgePurchasableUSD",result.toString())
        let amount = "1000000000000000000"
        result = await dashBoard.buyLeverageAmountsOut(contracts.leveragePool.address,tokenA.address,amount);
        console.log("buyLeverageAmountsOut",result[0].toString(),result[1].toString(),result[2].toString(),result[3].toString())
        result = await dashBoard.buyHedgeAmountsOut(contracts.leveragePool.address,tokenA.address,amount);
        console.log("buyHedgeAmountsOut",result[0].toString(),result[1].toString(),result[2].toString(),result[3].toString())
        result = await dashBoard.sellLeverageAmountsOut(contracts.leveragePool.address,amount,tokenA.address);
        console.log("sellLeverageAmountsOut",result[0].toString(),result[1].toString(),result[2].toString(),result[3].toString())
        result = await dashBoard.sellHedgeAmountsOut(contracts.leveragePool.address,amount,tokenA.address);
        console.log("sellHedgeAmountsOut",result[0].toString(),result[1].toString(),result[2].toString(),result[3].toString())

        result = await dashBoard.buyLeverageAmountsOut(contracts.leveragePool.address,tokenB.address,amount);
        console.log("buyLeverageAmountsOut",result[0].toString(),result[1].toString(),result[2].toString(),result[3].toString())
        result = await dashBoard.buyHedgeAmountsOut(contracts.leveragePool.address,tokenB.address,amount);
        console.log("buyHedgeAmountsOut",result[0].toString(),result[1].toString(),result[2].toString(),result[3].toString())
        result = await dashBoard.sellLeverageAmountsOut(contracts.leveragePool.address,amount,tokenB.address);
        console.log("sellLeverageAmountsOut",result[0].toString(),result[1].toString(),result[2].toString(),result[3].toString())
        result = await dashBoard.sellHedgeAmountsOut(contracts.leveragePool.address,amount,tokenB.address);
        console.log("sellHedgeAmountsOut",result[0].toString(),result[1].toString(),result[2].toString(),result[3].toString())

        result = await dashBoard.getSwapRouter(contracts.leveragePool.address);
        console.log("getSwapPath",result[0],result[1])
    }
});