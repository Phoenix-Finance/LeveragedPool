const { assert } = require("console");

const rebaseToken = artifacts.require("rebaseToken");
const phxProxy = artifacts.require("phxProxy");
const PHXCoin = artifacts.require("PHXCoin");
let eth = "0x0000000000000000000000000000000000000000";
const multiSignature = artifacts.require("multiSignature");
const testLeverageFactory = artifacts.require("testLeverageFactory");

contract('rebaseToken', function (accounts){
    it('rebaseToken normal tests', async function (){
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let rTokenImply = await rebaseToken.new(multiSign.address);
        let factory = await testLeverageFactory.new()
        await factory.createRebaseToken(rTokenImply.address,multiSign.address,"leverageToken","lToken",eth);
        let newToken = await factory.newContract();
        rToken = await rebaseToken.at(newToken);
//        await rToken.changeTokenName("leverageToken","lToken",eth);
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
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let rTokenImply = await rebaseToken.new(multiSign.address);
        let factory = await testLeverageFactory.new()
        await factory.createRebaseToken(rTokenImply.address,multiSign.address,"rebaseToken","rToken",eth);
        let newToken = await factory.newContract();
        rToken = await rebaseToken.at(newToken);
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
        let phx = await PHXCoin.new();
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let rTokenImply = await rebaseToken.new(multiSign.address);
        let factory = await testLeverageFactory.new()
        await factory.createRebaseToken(rTokenImply.address,multiSign.address,"rebaseToken","rToken",phx.address);
        let newToken = await factory.newContract();
        rToken = await rebaseToken.at(newToken);
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
        await phx.transfer(rToken.address,"100000000000000000000");
        await rToken.newErc20("100000000000000000000");
        await redeem(rToken,phx,accounts[0])
        await redeem(rToken,phx,accounts[1])
        await redeem(rToken,phx,accounts[2])
        await redeem(rToken,phx,accounts[3])
        await redeem(rToken,phx,accounts[4])
    })
    async function redeem(rToken,phx,account){
        let balance = await rToken.getRedeemAmount(account)
        console.log("balance : ",balance.toString());
        let preBalance = await phx.balanceOf(account)
        await rToken.redeemToken({from:account});
        let endBalance = await phx.balanceOf(account)
        assert(balance.toString() == endBalance.sub(preBalance).toString(),"redeemToken error")
    }
})