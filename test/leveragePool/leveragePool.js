
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

        let factoryInfo = await testInfo.createFactory(beforeInfo,true,accounts[0],accounts);
        let ethBalance = await beforeInfo.weth.balanceOf(beforeInfo.pair);
        console.log("WETH Balance : ",ethBalance.toString());
        let fnxBalance = await beforeInfo.fnx.balanceOf(beforeInfo.pair);
        console.log("FNX Balance : ",fnxBalance.toString());
        let assets = [beforeInfo.fnx.address,eth,beforeInfo.weth.address]
        let prices = [1e8,1e11,1e11]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);
        let contracts = await testInfo.createLeveragePool(factoryInfo,beforeInfo,accounts[0]);

        ethBalance = await beforeInfo.weth.balanceOf(beforeInfo.pair);
        console.log("WETH Balance : ",ethBalance.toString());
        fnxBalance = await beforeInfo.fnx.balanceOf(beforeInfo.pair);
        console.log("FNX Balance : ",fnxBalance.toString());

        let netWroth = await contracts.leveragePool.getTokenNetworths();
        console.log("net worth : ",netWroth[0].toString(),netWroth[1].toString());
        await contracts.leveragePool.rebalance();
        await beforeInfo.fnx.approve(contracts.stakepool[0].address,"1000000000000000000000");
        await contracts.stakepool[0].stake("1000000000000000000000");
        await contracts.stakepool[1].stake("1000000000000000000000",{from : accounts[8],value : "1000000000000000000000"});
        await contracts.leveragePool.rebalance();
        await leverageCheck.buyLeverage(eventDecoder,contracts,0,"1000000000000000000","9000000000000000",accounts[0]);
        ethBalance = await web3.eth.getBalance(contracts.leveragePool.address);
        fnxBalance = await beforeInfo.fnx.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",ethBalance.toString(),fnxBalance.toString())
        await leverageCheck.buyLeverage(eventDecoder,contracts,0,"1000000000000000000","9000000000000000",accounts[0]);
        ethBalance = await web3.eth.getBalance(contracts.leveragePool.address);
        fnxBalance = await beforeInfo.fnx.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",ethBalance.toString(),fnxBalance.toString())
        await leverageCheck.buyLeverage(eventDecoder,contracts,1,"1000000000000000000","9000000000000000",accounts[1]);
        ethBalance = await web3.eth.getBalance(contracts.leveragePool.address);
        fnxBalance = await beforeInfo.fnx.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",ethBalance.toString(),fnxBalance.toString())
        await leverageCheck.buyLeverage(eventDecoder,contracts,1,"1000000000000000000","9000000000000000",accounts[1]); 
        ethBalance = await web3.eth.getBalance(contracts.leveragePool.address);
        fnxBalance = await beforeInfo.fnx.balanceOf(contracts.leveragePool.address);
        console.log("Underlying balances : ",ethBalance.toString(),fnxBalance.toString())
        assets = [beforeInfo.fnx.address,eth,beforeInfo.weth.address]
        prices = [1e8,9e10,9e10]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]);     
        ethBalance = await beforeInfo.weth.balanceOf(beforeInfo.pair);
        console.log("WETH Balance : ",ethBalance.toString());
        fnxBalance = await beforeInfo.fnx.balanceOf(beforeInfo.pair);
        console.log("FNX Balance : ",fnxBalance.toString());  
        let receipt = await contracts.leveragePool.rebalance();
        let events = eventDecoder.decodeTxEvents(receipt);
        console.log(events);
        let getNetworth = await contracts.leveragePool.getTokenNetworths();
        console.log(getNetworth[0].toString(10),getNetworth[1].toString(10));
        getNetworth = await contracts.leveragePool.getLeverageRebase()
        console.log(getNetworth[0],getNetworth[1]);
        getNetworth = await contracts.leveragePool.getEnableLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        assets = [beforeInfo.fnx.address,eth,beforeInfo.weth.address]
        prices = [1e8,8e10,8e10]
        await testInfo.setOraclePrice(assets,prices,factoryInfo,beforeInfo.pair,accounts[0]); 
        receipt = await contracts.leveragePool.rebalance();
        events = eventDecoder.decodeTxEvents(receipt);
        console.log(events);
        getNetworth = await contracts.leveragePool.getTokenNetworths();
        console.log(getNetworth[0].toString(10),getNetworth[1].toString(10));
        getNetworth = await contracts.leveragePool.getLeverageRebase()
        console.log(getNetworth[0],getNetworth[1]);
        getNetworth = await contracts.leveragePool.getEnableLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        receipt = await contracts.leveragePool.rebalance();
        getNetworth = await contracts.leveragePool.getTokenNetworths();
        console.log(getNetworth[0].toString(10),getNetworth[1].toString(10));
        getNetworth = await contracts.leveragePool.getLeverageRebase()
        console.log(getNetworth[0],getNetworth[1]);
        getNetworth = await contracts.leveragePool.getEnableLiquidate()
        console.log(getNetworth[0],getNetworth[1]);
        assets = [beforeInfo.fnx.address,eth,beforeInfo.weth.address]
        prices = [1e8,5e10,5e10]
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
        return;
        ethBalance = await weth.balanceOf(pair);
        console.log("WETH Balance : ",ethBalance.toString());
        ethBalance = await web3.eth.getBalance(weth.address);
        console.log("ETH Balance : ",ethBalance.toString());
        ethBalance = await web3.eth.getBalance(lToken.address);
        console.log("ETH Balance1 : ",ethBalance.toString());
        fnxBalance = await fnx.balanceOf(lToken.address);
        console.log("FNX Balance : ",fnxBalance.toString());
        fnxBalance = await fnx.balanceOf(stakepoolA.address);
        console.log("FNX Balance : ",fnxBalance.toString());

        fnxBalance = await contracts.rebaseToken[0].balanceOf(accounts[0]);
        console.log("rebase Balance : ",fnxBalance.toString());
        await contracts.rebaseToken[0].approve(lToken.address,fnxBalance);
        await lToken.sellLeverage(fnxBalance,1000,leverageCheck.getDeadLine(),"0x");
        return;
        ethBalance = await weth.balanceOf(pair);
        console.log("WETH Balance : ",ethBalance.toString());
        ethBalance = await web3.eth.getBalance(weth.address);
        console.log("ETH Balance : ",ethBalance.toString());
        ethBalance = await web3.eth.getBalance(lToken.address);
        console.log("ETH Balance1 : ",ethBalance.toString());
        fnxBalance = await fnx.balanceOf(lToken.address);
        console.log("FNX Balance : ",fnxBalance.toString());
        fnxBalance = await fnx.balanceOf(stakepoolA.address);
        console.log("FNX Balance : ",fnxBalance.toString());
    });
});