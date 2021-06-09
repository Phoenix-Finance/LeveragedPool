

let leverageCheck = require("../check/leverageCheck.js");
let testInfo = require("./testInfo.js");
let eventDecoderClass = require("../contract/eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let FPTCoinAbi = require("../../build/contracts/FPTCoin.json").abi;
let leveragedPoolAbi = require("../../build/contracts/leveragedPool.json").abi;
let stakePoolAbi = require("../../build/contracts/stakePool.json").abi;
const leverageFactory = artifacts.require("leverageFactory");
const leveragedPool = artifacts.require("leveragedPool");
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
        //await testToken(beforeInfo.USDC,beforeInfo.WBTC,beforeInfo,accounts,false);
        await testUpdate();
    });
    async function testUpdate(){
//        let oracle = await FNXOracle.at("0x9841df6b23F13B8cA99e097607a7056c77aFe939");
//        let sync = await uniswapSync.at("0x4d2c33874e545115589bEb7775bcd532614258Ea");
        let factory = await leverageFactory.at("0x771CC350464B24A7b8D2409e17211c20cCf65E41");
        let lToken = await leveragedPool.new();
        await factory.upgradeLeveragePool(lToken.address);
    }
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
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);
        let contracts = await testInfo.createTokenLeveragePool(tokenA,tokenB,factoryInfo,beforeInfo,accounts[0],accounts);
        console.log("factory",factoryInfo.factory.address);
        console.log("leveragePool",contracts.leveragePool.address);
    }
});