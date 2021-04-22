const BN = require("bn.js");

const leveragedPool = artifacts.require("leveragedPool");
const rebaseToken = artifacts.require("rebaseToken");
const stakePool = artifacts.require("stakePool");
const FPTCoin = artifacts.require("FPTCoin");
const FNXOracle = artifacts.require("FNXOracle");
const leveragedFactroy = artifacts.require("leveragedFactroy");
const IUniswapV2Router02 = artifacts.require("IUniswapV2Router02");
const IUniswapV2Factory = artifacts.require("IUniswapV2Factory");
const uniswapSync = artifacts.require("uniswapSync");
const IERC20 = artifacts.require("IERC20");
const IWETH = artifacts.require("IWETH");
let eth = "0x0000000000000000000000000000000000000000";
module.exports = {
    before : async function() {
        let fnx = await IERC20.at("0x187498EC2e9270A088156Eb0543866b9cfdB98fd");
        let USDC = await IERC20.at("0x5560ce0b661D70B06CEE562293894aFa98a08fF1");
        let WBTC = await IERC20.at("0x1e4252F6514C9e9910CB1336608294e28D6589E8");
        let WETH = await IERC20.at("0x8D76559f411eCBB55704087606D265E3cea72ffa");
        let univ2 = "0xAFf49db8dba14f0623C384cCd0B06Eb742dD75Af";
        let routerV2 = await IUniswapV2Router02.at(univ2);
        let addr = await routerV2.factory();
        let uniFactory = await IUniswapV2Factory.at(addr);
        let wethaddr = await routerV2.WETH();
        let weth = await IWETH.at(wethaddr);
        let pair = await uniFactory.getPair(weth.address,fnx.address);
        return {
            fnx : fnx,
            USDC :USDC,
            WBTC :WBTC,
            WETH : WETH,
            univ2 : univ2,
            routerV2 : routerV2,
            uniFactory : uniFactory,
            weth : weth,
            pair : pair
        }
    },
    createFactory : async function(beforeInfo,bNewOracle,account) {
        let rTokenImply = await rebaseToken.new({from:account});
        let fptCoin = await FPTCoin.new({from:account});
        let oracle;
        let sync;
        if(bNewOracle){
            oracle = await FNXOracle.new();
            await oracle.setOperator(0,account,{from:account});
            sync = await uniswapSync.new(oracle.address);
            console.log("oracle Address : ",oracle.address)
            console.log("uniswapSync Address : ",sync.address)
        }else{
            oracle = await FNXOracle.at("0x3DbdeD8c4E401b4DFc3a0da7dAb2ec2709420984");
            sync = await uniswapSync.at("0x3CbcB87Cef03BF950af580BE988A50be763f57b7");
        }
        let stakeimple = await stakePool.new({from:account});
        let lToken = await leveragedPool.new({from:account});

        let lFactory = await leveragedFactroy.new({from:account});
        await lFactory.initFactroryInfo("ETH",stakeimple.address,lToken.address,fptCoin.address,rTokenImply.address,oracle.address,
        beforeInfo.univ2,account,1e5,1e5,1e5,5e7,1e7,1e5,{from:account});
        
        /*
        let amount = new BN("1000000000000000000000000000000");
        await beforeInfo.fnx.transfer(sync.address,amount,{from:account});
        amount = new BN("1000000000000000000000000000");
        await beforeInfo.weth.deposit({from:account,value:amount});
        await beforeInfo.weth.transfer(sync.address,amount,{from:account});
        console.log(oracle.address,sync.address);
        */
        return {
            oracle: oracle,
            factory : lFactory,
            uniSync : sync
        }
    },
    createTokenLeveragePool : async function(tokenA,tokenB,factoryInfo,beforeInfo,account) {
        await factoryInfo.factory.createStatePool(tokenA.address,1e5,{from:account});
        await factoryInfo.factory.createStatePool(tokenB.address,1e5,{from:account});
        let spoolAddress = await factoryInfo.factory.getStakePool(tokenA.address);
        let stakepoolA = await stakePool.at(spoolAddress);
        spoolAddress = await factoryInfo.factory.getStakePool(tokenB.address);
        let stakepoolB = await stakePool.at(spoolAddress);
        await factoryInfo.factory.createLeveragePool(tokenA.address,tokenB.address,3e8,"100000000000000000000","100000000000000000",{from:account});  
        spoolAddress = await factoryInfo.factory.getLeveragePool(tokenA.address,tokenB.address,3e8);
        lToken = await leveragedPool.at(spoolAddress[2]);
        let leverageInfo = await lToken.getLeverageInfo();
        let hedgeInfo = await lToken.getHedgeInfo();
        let contracts = {
            oracle : factoryInfo.oracle,
            tokenAddr : [tokenA.address,tokenB.address],
            token : [tokenA,tokenB],
            stakepool : [stakepoolA,stakepoolB],
            leveragePool : lToken,
            info : [leverageInfo,hedgeInfo],
            rebaseToken : [await IERC20.at(leverageInfo[2]),await IERC20.at(hedgeInfo[2])]
        }
        return contracts;
    },
    createLeveragePool : async function(factoryInfo,beforeInfo,account) {
        await factoryInfo.factory.createStatePool(beforeInfo.fnx.address,1e5,{from:account});
        await factoryInfo.factory.createStatePool(eth,1e5,{from:account});
        let spoolAddress = await factoryInfo.factory.getStakePool(beforeInfo.fnx.address);
        let stakepoolA = await stakePool.at(spoolAddress);
        spoolAddress = await factoryInfo.factory.getStakePool(eth);
        let stakepoolB = await stakePool.at(spoolAddress);
        await factoryInfo.factory.createLeveragePool(beforeInfo.fnx.address,eth,3e8,"100000000000000000000","100000000000000000",{from:account});  
        spoolAddress = await factoryInfo.factory.getLeveragePool(beforeInfo.fnx.address,eth,3e8);
        lToken = await leveragedPool.at(spoolAddress[2]);
        let leverageInfo = await lToken.getLeverageInfo();
        let hedgeInfo = await lToken.getHedgeInfo();
        let contracts = {
            oracle : factoryInfo.oracle,
            tokenAddr : [beforeInfo.fnx.address,eth],
            token : [beforeInfo.fnx,eth],
            stakepool : [stakepoolA,stakepoolB],
            leveragePool : lToken,
            info : [leverageInfo,hedgeInfo],
            rebaseToken : [await IERC20.at(leverageInfo[2]),await IERC20.at(hedgeInfo[2])]
        }
        return contracts;
    },
    addLiquidity : async function(beforeInfo,factoryInfo,tokenA,tokenB,account) {
        let amount = "10000000000000000000000";
        await tokenA.approve(beforeInfo.univ2,amount,{from:account});
        await tokenB.approve(beforeInfo.univ2,amount,{from:account});
        await beforeInfo.routerV2.addLiquidity(tokenA.address,tokenB.address,amount,amount,amount,amount,account,3625460000,{from:account})
        let pair = await beforeInfo.uniFactory.getPair(tokenA.address,tokenB.address);
        beforeInfo.pair = pair;
        amount = "10000000000000000000000000000000000000";
        await tokenA.transfer(factoryInfo.uniSync.address,amount,{from:account});
        await tokenB.transfer(factoryInfo.uniSync.address,amount,{from:account});
    },
    setOraclePrice: async function(assets,assetPrices,factoryInfo,pair,account){
        await factoryInfo.oracle.setPriceAndUnderlyingPrice(assets,assetPrices,[],[],{from:account});
        await factoryInfo.uniSync.syncPair(pair,{from:account});
    }
}