
const leveragedPool = artifacts.require("leveragedPool");
const rebaseToken = artifacts.require("rebaseToken");
const stakePool = artifacts.require("stakePool");
const stakePoolProxy = artifacts.require("stakePoolProxy");
const FPTCoin = artifacts.require("FPTCoin");
const IERC20 = artifacts.require("IERC20");
const FNXOracle = artifacts.require("FNXOracle");
const IUniswapV2Router02 = artifacts.require("IUniswapV2Router02");
const IUniswapV2Factory = artifacts.require("IUniswapV2Factory");
const leveragedFactroy = artifacts.require("leveragedFactroy");
let leverageCheck = require("../check/leverageCheck.js");
let eventDecoderClass = require("../contract/eventDecoder.js")
let eth = "0x0000000000000000000000000000000000000000";
let FPTCoinAbi = require("../../build/contracts/FPTCoin.json").abi;
let leveragedPoolAbi = require("../../build/contracts/leveragedPool.json").abi;
let stakePoolAbi = require("../../build/contracts/stakePool.json").abi;
contract('leveragedPool', function (accounts){
    let fnx;
    let univ2;
    let routerV2;
    let uniFactory;
    let weth;
    let eventDecoder;
    before(async () => {
        fnx = await IERC20.at("0x8Fab2f69f9E3D60bF3873805092a37083D651B30");
        univ2 = "0xD48C1223A884d01cF8Bde22b2d87E21BC372D7D8";
        routerV2 = await IUniswapV2Router02.at(univ2);
        let addr = await routerV2.factory();
        uniFactory = await IUniswapV2Factory.at(addr);
        let wethaddr = await routerV2.WETH();
        weth = await IERC20.at(wethaddr);
        eventDecoder = new eventDecoderClass();
        eventDecoder.initEventsMap([FPTCoinAbi,leveragedPoolAbi,stakePoolAbi]);
    }); 
    it('leveragedPool normal tests', async function (){

        let rTokenImply = await rebaseToken.new();
        let fptCoin = await FPTCoin.new();
        let oracle = await FNXOracle.new();
        await oracle.setOperator(0,accounts[0]);
        await oracle.setPrice(fnx.address,1e8);
        await oracle.setPrice(eth,1e11);
        let stakeimple = await stakePool.new();
        let lToken = await leveragedPool.new();

        let lFactory = await leveragedFactroy.new();
        await lFactory.initFactroryInfo("ETH",stakeimple.address,lToken.address,fptCoin.address,rTokenImply.address,oracle.address,
            univ2,accounts[1],1e5,1e5,1e5,5e6,1e5);
            await lFactory.createStatePool(fnx.address,1e5);
            await lFactory.createStatePool(eth,1e5);
        let spoolAddress = await lFactory.getStakePool(fnx.address);
        let stakepoolA = await stakePool.at(spoolAddress);
        spoolAddress = await lFactory.getStakePool(eth);
        let stakepoolB = await stakePool.at(spoolAddress);
        await lFactory.createLeveragePool(fnx.address,eth,3e8,"100000000000000000000","100000000000000000");

        spoolAddress = await lFactory.getLeveragePool(fnx.address,eth,3e8);
        lToken = await leveragedPool.at(spoolAddress[2]);
        let tokens = await lToken.leverageTokens();
        let contracts = {
            tokenAddr : [fnx.address,eth],
            token : [fnx,eth],
            stakepool : [stakepoolA,stakepoolB],
            leveragePool : lToken,
            oracle: oracle,
            rebaseToken : [await IERC20.at(tokens[0]),await IERC20.at(tokens[0])]
        }
        
        console.log("tokens : ",tokens);
        let pair = await uniFactory.getPair(weth.address,fnx.address);
        let ethBalance = await weth.balanceOf(pair);
        console.log("WETH Balance : ",ethBalance.toString());
        ethBalance = await web3.eth.getBalance(weth.address);
        console.log("ETH Balance : ",ethBalance.toString());
        let fnxBalance = await fnx.balanceOf(pair);
        console.log("FNX Balance : ",fnxBalance.toString());

        /*
        let amount = "10000000000000000000000000";
        let ethAmount =    "10000000000000000000000";
        await fnx.transfer(accounts[9],amount);
        await fnx.approve(routerV2.address,amount,{from:accounts[9]});
        await routerV2.addLiquidityETH(fnx.address,amount,amount,
            ethAmount,accounts[0],1625460000,{
                    from:accounts[9],value:ethAmount});
*/
        let result = await lToken.getLeverageFee();
        console.log("Leverage fee : ",result[0].toString(),result[1].toString(),result[2].toString());
        let netWroth = await lToken.getTokenNetworths();
        console.log("net worth : ",netWroth[0].toString(),netWroth[1].toString());
        await fnx.approve(stakepoolA.address,"1000000000000000000000");
        await stakepoolA.stake("1000000000000000000000");
        await leverageCheck.buyLeverage(eventDecoder,contracts,0,"1000000000000000000","9000000000000000",accounts[0]);
        await leverageCheck.buyLeverage(eventDecoder,contracts,0,"1000000000000000000","9000000000000000",accounts[0]);
        
        await lToken.rebalance();
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

        fnxBalance = await rebaseToken1.balanceOf(accounts[0]);
        console.log("rebase Balance : ",fnxBalance.toString());
        await rebaseToken1.approve(lToken.address,fnxBalance);
        await lToken.sellLeverage(fnxBalance,1000,"0x");

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