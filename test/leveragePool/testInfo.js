const BN = require("bn.js");

const leveragedPool = artifacts.require("leveragedPool");
const rebaseToken = artifacts.require("rebaseToken");
const stakePool = artifacts.require("stakePool");
const PPTCoin = artifacts.require("PPTCoin");
const PHXOracle = artifacts.require("PHXOracle");
const leverageFactory = artifacts.require("leverageFactory");
const phxProxy = artifacts.require("phxProxy");
const acceleratedMinePool = artifacts.require("acceleratedMinePool");
const PHXAccelerator = artifacts.require("PHXAccelerator");
const multiSignature = artifacts.require("multiSignature");
const IUniswapV2Router02 = artifacts.require("IUniswapV2Router02");
const IUniswapV2Factory = artifacts.require("IUniswapV2Factory");
const uniswapSync = artifacts.require("uniswapSync");
const UniSwapRouter = artifacts.require("UniSwapRouter");
const IERC20 = artifacts.require("IERC20");
const IWETH = artifacts.require("IWETH");
let eth = "0x0000000000000000000000000000000000000000";
module.exports = {
    before : async function() {
        let fnx = await IERC20.at("0x982c1E6bd1550c1702fEc0C7cf8E4eb358BD39ef");
        let USDC = await IERC20.at("0x62f364c7127A16CE91dD68acB8476992044F5b39");
        let WBTC = await IERC20.at("0xfD7601e484cc5532Beb5CB2ee52014EaFCAF3DAE");
        let WETH = await IERC20.at("0x755C76b93c41e5Efb3966d9473Cfc79c31248F4D");
        let univ2 = "0x82058af5c505D2A001d2600f645Ad188d626b77c";
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
    createFactory : async function(beforeInfo,bNewOracle,account,accounts) {
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let rTokenImply = await rebaseToken.new(multiSign.address,{from:account});
        let pptCoin = await PPTCoin.new(multiSign.address,{from:account});
        let oracle;
        let sync;
        if(bNewOracle){
            oracle = await PHXOracle.new();
            await oracle.setOperator(3,account,{from:account});
            sync = await uniswapSync.new(oracle.address);
            console.log("oracle Address : ",oracle.address)
            console.log("uniswapSync Address : ",sync.address)
        }else{
            oracle = await PHXOracle.at("0x42d04599c41580C99f6F9cf26Ac7999Ef0cA8C36");
            sync = await uniswapSync.at("0xE948e0674044d9983E4864b74E440a655E2b14a9");
        }
        let stakeimple = await stakePool.new(multiSign.address,{from:account});
        let lToken = await leveragedPool.new(multiSign.address,{from:account});

        let uniswap = await UniSwapRouter.new({from:account});
        let accelerator = await PHXAccelerator.new(multiSign.address,{from:account});
        let acceleratorProxy = await phxProxy.new(accelerator.address,multiSign.address,{from:account});
        accelerator = await PHXAccelerator.at(acceleratorProxy.address)
        await accelerator.initMineLockedInfo(1622995200,86400*90,12,86400*15);
        let minePool = await acceleratedMinePool.new(multiSign.address,{from:account})
        let lFactory = await leverageFactory.new(multiSign.address,{from:account});
        proxy = await phxProxy.new(lFactory.address,multiSign.address,{from:account});
        lFactory = await leverageFactory.at(proxy.address);
        await lFactory.setImplementAddress("ETH",account,account,stakeimple.address,lToken.address,pptCoin.address,
            rTokenImply.address,minePool.address,acceleratorProxy.address,oracle.address)
        await lFactory.initFactoryInfo(beforeInfo.univ2,uniswap.address,1,1e5,1e5,1e5,15e7,1e7,1001e5,{from:account});
        await this.multiSignatureAndSend(multiSign,lFactory,"setOperator",account,accounts,1,account)
        let operator = await lFactory.getOperator(1)
        console.log("operator address",operator)
//        await lFactory.setOperator(1,account,{from:account});
        
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
            multiSignature : multiSign,
            factory : lFactory,
            uniSync : sync
        }
    },
    multiSignatureAndSend: async function(multiContract,toContract,method,account,accounts,...args){
        let msgData = await toContract.contract.methods[method](...args).encodeABI();
        let hash = await this.createApplication(multiContract,account,toContract.address,0,msgData)
        let index = await multiContract.getApplicationCount(hash)
        index = index.toNumber()-1;
        await multiContract.signApplication(hash,index,{from:accounts[1]})
        await multiContract.signApplication(hash,index,{from:accounts[2]})
        await multiContract.signApplication(hash,index,{from:accounts[4]})
        await toContract[method](...args);
    },
    createApplication: async function (multiSign,account,to,value,message){
        await multiSign.createApplication(to,value,message,{from:account});
        return await multiSign.getApplicationHash(account,to,value,message)
    },
    createTokenLeveragePool : async function(tokenA,tokenB,factoryInfo,beforeInfo,account,accounts) {
        await this.multiSignatureAndSend(factoryInfo.multiSignature,factoryInfo.factory,"createStatePool",account,accounts,tokenA.address,1e5)
        await this.multiSignatureAndSend(factoryInfo.multiSignature,factoryInfo.factory,"createStatePool",account,accounts,tokenB.address,1e5)
        let spoolAddress = await factoryInfo.factory.getStakePool(tokenA.address);
        let stakepoolA = await stakePool.at(spoolAddress);
        spoolAddress = await factoryInfo.factory.getStakePool(tokenB.address);
        let stakepoolB = await stakePool.at(spoolAddress);
        await this.multiSignatureAndSend(factoryInfo.multiSignature,factoryInfo.factory,"createLeveragePool",account,accounts,tokenA.address,tokenB.address,3e8,1e10)
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