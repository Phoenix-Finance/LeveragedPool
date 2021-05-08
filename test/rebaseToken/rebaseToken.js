const { assert } = require("console");

const rebaseToken = artifacts.require("rebaseToken");
const fnxProxy = artifacts.require("fnxProxy");
const IERC20 = artifacts.require("IERC20");
let eth = "0x0000000000000000000000000000000000000000";
contract('rebaseToken', function (accounts){
    it('rebaseToken normal tests', async function (){
        let rTokenImply = await rebaseToken.new();
        let rToken = await fnxProxy.new(rTokenImply.address);
        rToken = await rebaseToken.at(rToken.address);
        await rToken.modifyPermission(accounts[0],0xFFFFFFFFFFFF);
        await rToken.changeTokenName("leverageToken","lToken",eth);
        let name = await rToken.name();
        console.log(name);
        let symbol = await rToken.symbol();
        console.log(symbol);
        let decimals = await rToken.decimals();
        console.log(decimals.toNumber());
        let totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        let balance = await rToken.balanceOf(accounts[0]);
        console.log("balance 0 :",balance.toString());
        await rToken.mint(accounts[1],10000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        balance = await rToken.balanceOf(accounts[1]);
        console.log("balance 1 :",balance.toString());
        await rToken.calRebaseRatio(90000000000);
        await rToken.mint(accounts[2],10000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        balance = await rToken.balanceOf(accounts[1]);
        console.log("balance 1 :",balance.toString());
        balance = await rToken.balanceOf(accounts[2]);
        console.log("balance 2 :",balance.toString());
        await rToken.calRebaseRatio(9000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        balance = await rToken.balanceOf(accounts[1]);
        console.log("balance 1 :",balance.toString());
        balance = await rToken.balanceOf(accounts[2]);
        console.log("balance 2 :",balance.toString());
        await rToken.mint(accounts[0],10000000000);
        await rToken.transfer(accounts[3],5000000000);
        balance = await rToken.balanceOf(accounts[0]);
        console.log("balance 0 :",balance.toString());
        balance = await rToken.balanceOf(accounts[3]);
        console.log("balance 3 :",balance.toString());
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
    })
    it('rebaseToken proxy normal tests', async function (){
        let rTokenImply = await rebaseToken.new();
        let rToken = await fnxProxy.new(rTokenImply.address);
        rToken = await rebaseToken.at(rToken.address);
        await rToken.modifyPermission(accounts[0],0xFFFFFFFFFFFF);
        rToken.changeTokenName("rebase Token","RBT",eth);
        let name = await rToken.name();
        console.log(name);
        let symbol = await rToken.symbol();
        console.log(symbol);
        let decimals = await rToken.decimals();
        console.log(decimals.toNumber());
        let totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        let balance = await rToken.balanceOf(accounts[0]);
        console.log("balance 0 :",balance.toString());
        await rToken.mint(accounts[1],10000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        balance = await rToken.balanceOf(accounts[1]);
        console.log("balance 1 :",balance.toString());
        await rToken.calRebaseRatio(90000000000);
        await rToken.mint(accounts[2],10000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        balance = await rToken.balanceOf(accounts[1]);
        console.log("balance 1 :",balance.toString());
        balance = await rToken.balanceOf(accounts[2]);
        console.log("balance 2 :",balance.toString());
        await rToken.calRebaseRatio(9000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        balance = await rToken.balanceOf(accounts[1]);
        console.log("balance 1 :",balance.toString());
        balance = await rToken.balanceOf(accounts[2]);
        console.log("balance 2 :",balance.toString());
        await rToken.mint(accounts[0],10000000000);
        await rToken.transfer(accounts[3],5000000000);
        balance = await rToken.balanceOf(accounts[0]);
        console.log("balance 0 :",balance.toString());
        balance = await rToken.balanceOf(accounts[3]);
        console.log("balance 3 :",balance.toString());
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
    })
    it('rebaseToken proxy redeem tests', async function (){
        let rTokenImply = await rebaseToken.new();
        let rToken = await fnxProxy.new(rTokenImply.address);
        rToken = await rebaseToken.at(rToken.address);
        await rToken.modifyPermission(accounts[0],0xFFFFFFFFFFFF);
        let fnx = await IERC20.at("0xcfD494f8aF60ca86D0936e99dF3904f590c86A57");
        rToken.changeTokenName("rebase Token","RBT",fnx.address);
        let totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        await rToken.mint(accounts[1],10000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        await rToken.calRebaseRatio(90000000000);
        await rToken.mint(accounts[2],10000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        await rToken.calRebaseRatio(9000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        await rToken.mint(accounts[0],10000000000);
        await rToken.transfer(accounts[3],5000000000);
        totalSupply = await rToken.totalSupply();
        console.log("totalSupply : ",totalSupply.toString());
        await fnx.transfer(rToken.address,"100000000000000000000");
        await rToken.newErc20("100000000000000000000");
        await redeem(rToken,fnx,accounts[0])
        await redeem(rToken,fnx,accounts[1])
        await redeem(rToken,fnx,accounts[2])
        await redeem(rToken,fnx,accounts[3])
        await redeem(rToken,fnx,accounts[4])
    })
    async function redeem(rToken,fnx,account){
        let balance = await rToken.getRedeemAmount(account)
        console.log("balance : ",balance.toString());
        let preBalance = await fnx.balanceOf(account)
        await rToken.redeemToken({from:account});
        let endBalance = await fnx.balanceOf(account)
        assert(balance.toString() == endBalance.sub(preBalance).toString(),"redeemToken error")
    }
})