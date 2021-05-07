const BN = require("bn.js");

const leveragedPool = artifacts.require("leveragedPool");
const rebaseToken = artifacts.require("rebaseToken");
const stakePool = artifacts.require("stakePool");
const FPTCoin = artifacts.require("FPTCoin");
const FNXOracle = artifacts.require("FNXOracle");
const leverageFactory = artifacts.require("leverageFactory");
const fnxProxy = artifacts.require("fnxProxy");
const IUniswapV2Router02 = artifacts.require("IUniswapV2Router02");
const IUniswapV2Factory = artifacts.require("IUniswapV2Factory");
const uniswapSync = artifacts.require("uniswapSync");
const IERC20 = artifacts.require("IERC20");
const IWETH = artifacts.require("IWETH");
let eth = "0x0000000000000000000000000000000000000000";
module.exports = {
    before : async function() {
        let fnx = await IERC20.at("0xcfD494f8aF60ca86D0936e99dF3904f590c86A57");
        let USDC = await IERC20.at("0xD5F99d02f2eD78B168cc13067c56DfDa5a3DfaBA");
        let WBTC = await IERC20.at("0x9be7B0D8c7a2d2559DDd4996B5B80697f168eD33");
        let WETH = await IERC20.at("0x9d3943c9c360aD3928B8d9EA18fEAac0b651963b");
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
            oracle = await FNXOracle.at("0x9841df6b23F13B8cA99e097607a7056c77aFe939");
            sync = await uniswapSync.at("0x4d2c33874e545115589bEb7775bcd532614258Ea");
        }
        let stakeimple = await stakePool.new({from:account});
        let lToken = await leveragedPool.new({from:account});

        let lFactory = await leverageFactory.new({from:account});
        console.log("leverageFactory.new : ",lFactory.address);
        let proxy = await fnxProxy.new(lFactory.address,{from:account});
        console.log("fnxProxy.new : ",proxy.address);
        lFactory = await leverageFactory.at(proxy.address);
        console.log("leverageFactory.at : ",lFactory.address);
        await lFactory.initFactoryInfo("ETH",stakeimple.address,lToken.address,fptCoin.address,rTokenImply.address,oracle.address,
        beforeInfo.univ2,account,1e5,1e5,1e5,15e7,1e7,1e5,{from:account});
        await lFactory.modifyPermission(account,0xFFFFFFFF,{from:account});
        
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
        let decimalsA = await tokenA.decimals()
        let decimalsB = await tokenB.decimals()
        let base = new BN(10);
        let tokenRebase0 = (new BN(100)).mul(base.pow(new BN(decimalsA)));
        let tokenRebase1 = (new BN(1)).mul(base.pow(new BN(decimalsB-2)));
        await factoryInfo.factory.createLeveragePool(tokenA.address,tokenB.address,3e8,1e10,{from:account});  
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

        console.log("rebase worth :",tokenRebase0.toString(),tokenRebase1.toString())
        await factoryInfo.factory.createLeveragePool(beforeInfo.fnx.address,eth,3e8,1e11,{from:account});  
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
        await factoryInfo.uniSync.syncPair(pair,{from:account});
    }
}