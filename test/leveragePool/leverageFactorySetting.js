
let leverageCheck = require("../check/leverageCheck.js");
let testInfo = require("./testInfo.js");
let eventDecoderClass = require("../contract/eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let FPTCoinAbi = require("../../build/contracts/FPTCoin.json").abi;
let leveragedPoolAbi = require("../../build/contracts/leveragedPool.json").abi;
let stakePoolAbi = require("../../build/contracts/stakePool.json").abi;
const IERC20 = artifacts.require("IERC20");
const timeLimitation = artifacts.require("timeLimitation");
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
        let priceB = new BN(6e12);
        priceB = priceB.mul(base.pow(new BN(18-decimalsB)));
        let assets = [tokenA.address,tokenB.address]
        let prices = [priceA,priceB]
        console.log(priceA.toString(),priceB.toString());
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);
        let contracts = await testInfo.createTokenLeveragePool(tokenA,tokenB,factoryInfo,beforeInfo,accounts[0],accounts);
        let testAddr = "0x9d3943c9c360aD3928B8d9EA18fEAac0b651963b";
        await factoryInfo.factory.setUniswapAddress(testAddr);
        let getAddr = await contracts.leveragePool.IUniswap()
        assert.equal(testAddr,getAddr,"setUniswapAddress error")
        await factoryInfo.factory.setOracleAddress(testAddr);
        getAddr = await contracts.leveragePool.getOracleAddress()
        assert.equal(testAddr,getAddr,"setOracleAddress error")
        await factoryInfo.factory.setFeeAddress(testAddr);
        getAddr = await contracts.leveragePool.feeAddress()
        assert.equal(testAddr,getAddr,"setFeeAddress error")
        await factoryInfo.factory.setLeverageFee(100000,200000,300000);
        await factoryInfo.factory.setRebaseTimeLimit(50);
        let reToken = await timeLimitation.at(contracts.rebaseToken[0].address)
        getAddr = await reToken.limitation()
        assert.equal(getAddr.toNumber(),50,"setFeeAddress error")
        reToken = await timeLimitation.at(contracts.rebaseToken[1].address)
        getAddr = await reToken.limitation()
        assert.equal(getAddr.toNumber(),50,"setFeeAddress error")
        await factoryInfo.factory.setFPTTimeLimit(40);
        let fptAddr = await contracts.stakepool[0].getPPTCoinAddress()
        reToken = await timeLimitation.at(fptAddr)
        getAddr = await reToken.limitation()
        assert.equal(getAddr.toNumber(),40,"setFeeAddress error")
        fptAddr = await contracts.stakepool[1].getPPTCoinAddress()
        reToken = await timeLimitation.at(fptAddr)
        getAddr = await reToken.limitation()
        assert.equal(getAddr.toNumber(),40,"setFeeAddress error")
    }
});