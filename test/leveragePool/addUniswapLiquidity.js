const BN = require("bn.js");

const leveragedPool = artifacts.require("leveragedPool");
const rebaseToken = artifacts.require("rebaseToken");
const stakePool = artifacts.require("stakePool");
const FPTCoin = artifacts.require("FPTCoin");
const FNXOracle = artifacts.require("FNXOracle");
const leverageFactory = artifacts.require("leverageFactory");
const IUniswapV2Router02 = artifacts.require("IUniswapV2Router02");
const IUniswapV2Factory = artifacts.require("IUniswapV2Factory");
const uniswapSync = artifacts.require("uniswapSync");
const IERC20 = artifacts.require("IERC20");
const IWETH = artifacts.require("IWETH");
let eth = "0x0000000000000000000000000000000000000000";
module.exports = {
    addLiquidity : async function(beforeInfo,factoryInfo,tokenA,tokenB,account) {
        let amount = "10000000000000000000000000";
        await tokenA.approve(beforeInfo.univ2,amount,{from:account});
        await tokenB.approve(beforeInfo.univ2,amount,{from:account});
        beforeInfo.routerV2.addLiquidity(tokenA,tokenB,amount,amount,amount,amount,account,3625460000,{from:account})
        let pair = await beforeInfo.uniFactory.getPair(tokenA.address,tokenB.address);
        beforeInfo.pair = pair;
        let amount = "1000000000000000000000000000000000";
        tokenA.transfer(factoryInfo.uniSync.address,amount,{from:account});
        tokenB.transfer(factoryInfo.uniSync.address,amount,{from:account});
    },
    createFactory : async function(beforeInfo,account) {
        let rTokenImply = await rebaseToken.new({from:account});
        let fptCoin = await FPTCoin.new({from:account});
        let oracle = await FNXOracle.at("0x42b7aAE642A9AD338BCF9c6B0D710EAaE81b4213");
        await oracle.setOperator(0,account,{from:account});
        
        let stakeimple = await stakePool.new({from:account});
        let lToken = await leveragedPool.new({from:account});

        let lFactory = await leverageFactory.new({from:account});
        await lFactory.initFactoryInfo("ETH",stakeimple.address,lToken.address,fptCoin.address,rTokenImply.address,oracle.address,
        beforeInfo.univ2,account,1e5,1e5,1e5,5e7,1e7,1e5,{from:account});
        let sync = await uniswapSync.at("0xf08D2CB5eDa498a733b5DD5d570bF75Ab311A14c");
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
    setOraclePrice: async function(assets,assetPrices,factoryInfo,pair,account){
        await factoryInfo.oracle.setPriceAndUnderlyingPrice(assets,assetPrices,[],[],{from:account});
        await factoryInfo.uniSync.syncPair(pair,{from:account});
    }
}