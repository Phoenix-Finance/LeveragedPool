
const leveragedPool = artifacts.require("leveragedPool");
const rebaseToken = artifacts.require("rebaseToken");
const stakePool = artifacts.require("stakePool");
const fnxProxy = artifacts.require("fnxProxy");
const FPTCoin = artifacts.require("FPTCoin");
const IERC20 = artifacts.require("IERC20");
const FNXOracle = artifacts.require("FNXOracle");
const IUniswapV2Router02 = artifacts.require("IUniswapV2Router02");
const IUniswapV2Factory = artifacts.require("IUniswapV2Factory");
const leverageFactory = artifacts.require("leverageFactory");
let eth = "0x0000000000000000000000000000000000000000";
contract('leveragedPool', function (accounts){
    let fnx;
    let univ2;
    let routerV2;
    let uniFactory;
    let weth;
    before(async () => {
        fnx = await IERC20.at("0x6084d548B66F03239041c3698Bbcd213d152845F");
        univ2 = "0x948EB179eeAFD0617CC881DE74771BDF3727503e";
        routerV2 = await IUniswapV2Router02.at(univ2);
        let addr = await routerV2.factory();
        uniFactory = await IUniswapV2Factory.at(addr);
        let wethaddr = await routerV2.WETH();
        weth = await IERC20.at(wethaddr);
    }); 
    it('leverageFactory normal tests', async function (){

        let rTokenImply = await rebaseToken.new();
        let fptCoin = await FPTCoin.new();
        let oracle = await FNXOracle.new();
        await oracle.setOperator(0,accounts[0]);
        await oracle.setPrice(fnx.address,1e8);
        await oracle.setPrice(eth,1e11);
        let stakeimple = await stakePool.new();
        let lToken = await leveragedPool.new();

        let lFactory = await leverageFactory.new();
        await lFactory.initFactoryInfo("ETH",stakeimple.address,lToken.address,fptCoin.address,rTokenImply.address,oracle.address,
            univ2,accounts[1],1,1e5,1e5,1e5,5e6,1001e5);
        let fnxCoin = await FPTCoin.new();
        fnxCoin.changeTokenName("Finnexus coin","FNX");
        await oracle.setPrice(fnxCoin.address,1e8);
        await lFactory.createStatePool(fnxCoin.address,1e5);
        let spoolAddress = await lFactory.getStakePool(fnxCoin.address);
        let spool = await stakePool.at(spoolAddress);
        let address = await spool.poolToken();
        console.log(fnxCoin.address,address);
        let fpt1 = await spool.getPPTCoinAddress();
        fpt1 = await FPTCoin.at(fpt1);
        console.log(fpt1.address,await fpt1.name(),await fpt1.symbol());
        await lFactory.createStatePool(eth,1e5);
        spoolAddress = await lFactory.getStakePool(eth);
        spool = await stakePool.at(spoolAddress);
        address = await spool.poolToken();
        console.log(address);
        fpt1 = await spool.getPPTCoinAddress();
        fpt1 = await FPTCoin.at(fpt1);
        console.log(fpt1.address,await fpt1.name(),await fpt1.symbol());

        await lFactory.createLeveragePool(fnxCoin.address,eth,22e7,"100000000000000000000","100000000000000000");

        spoolAddress = await lFactory.getLeveragePool(fnxCoin.address,eth,22e7);
        console.log(spoolAddress);
        spool = await leveragedPool.at(spoolAddress[2]);
        address = await spool.leverageTokens();
        console.log(address);
        let rpt1 = await rebaseToken.at(address[0]);
        let rpt2 = await rebaseToken.at(address[1]);
        console.log(spool.address,await rpt1.name(),await rpt2.name());
    });
});