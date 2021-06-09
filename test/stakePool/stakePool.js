const stakePoolCon = artifacts.require("stakePool");
const phxProxy = artifacts.require("phxProxy");
const PPTCoin = artifacts.require("PPTCoin");
const multiSignature = artifacts.require("multiSignature");
const PHXCoin = artifacts.require("PHXCoin");
const testLeverageFactory = artifacts.require("testLeverageFactory");
contract('stakePool', function (accounts){
    it('stakePool normal tests', async function (){
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let phx = await PHXCoin.new();
        let stakepool = await stakePoolCon.new(multiSign.address);
        let pptCoin = await PPTCoin.new(multiSign.address);
        let factory = await testLeverageFactory.new()
        await factory.createStakePool(stakepool.address,pptCoin.address,multiSign.address,"PPTA","PPTA",phx.address,1e5)
        let newToken = await factory.newContract();
        stakepool = await stakePoolCon.at(newToken)
        let addr = await stakepool.getPPTCoinAddress();
        console.log("getPPTCoinAddress : ",addr);
        addr = await stakepool.poolToken();
        console.log("poolToken : ",addr);
        let interest = await stakepool.interestRate();
        console.log("interestRate : ",interest.toNumber());
        interest = await stakepool.poolBalance();
        console.log("poolBalance : ",interest.toNumber());
        interest = await stakepool.PPTTotalSuply();
        console.log("PPTTotalSuply : ",interest.toNumber());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toNumber());
    });
    it('stakePool stake tests', async function (){
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let phx = await PHXCoin.new();
        let stakepool = await stakePoolCon.new(multiSign.address);
        let pptCoin = await PPTCoin.new(multiSign.address);
        let factory = await testLeverageFactory.new()
        await factory.createStakePool(stakepool.address,pptCoin.address,multiSign.address,"PPTA","PPTA",phx.address,1e5)
        let newToken = await factory.newContract();
        stakepool = await stakePoolCon.at(newToken);
        let addr = await stakepool.getPPTCoinAddress();
        console.log("getPPTCoinAddress : ",addr);
        addr = await stakepool.poolToken();
        console.log("poolToken : ",addr);
        let interest = await stakepool.interestRate();
        console.log("interestRate : ",interest.toNumber());
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        for(var i=0;i<100;i++){
            await stakepool.interestRate();
        }
        interest = await phx.balanceOf(accounts[0]);
        console.log("poolBalance : ",interest.toString());
        interest = await stakepool.poolBalance();
        console.log("poolBalance : ",interest.toString());
        interest = await stakepool.PPTTotalSuply();
        console.log("PPTTotalSuply : ",interest.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await stakepool.unstake("1000000000000000000");
        interest = await phx.balanceOf(accounts[0]);
        console.log("poolBalance : ",interest.toString());
        interest = await stakepool.poolBalance();
        console.log("poolBalance : ",interest.toString());
        interest = await stakepool.PPTTotalSuply();
        console.log("PPTTotalSuply : ",interest.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
    });
    it('stakePool borrow tests', async function (){
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let phx = await PHXCoin.new();
        let stakepool = await stakePoolCon.new(multiSign.address);
        let pptCoin = await PPTCoin.new(multiSign.address);
        let factory = await testLeverageFactory.new()
        await factory.createStakePool(stakepool.address,pptCoin.address,multiSign.address,"PPTA","PPTA",phx.address,1e5)
        let newToken = await factory.newContract();
        stakepool = await stakePoolCon.at(newToken);
        let addr = await stakepool.getPPTCoinAddress();
        console.log("getPPTCoinAddress : ",addr);
        addr = await stakepool.poolToken();
        console.log("poolToken : ",addr);
        let interest = await stakepool.interestRate();
        console.log("interestRate : ",interest.toNumber());
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        await stakepool.borrow("1000000000000000000");
        let balance = await phx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await phx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        await stakepool.borrowAndInterest("1000000000000000000");
        balance = await phx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await phx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.repayAndInterest("1000000000000000000"); 
        balance = await phx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await phx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await phx.mint(accounts[0],"1000000000000000000");
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.repay("1000000000000000000",false); 
        balance = await phx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await phx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
    });
    it('IStakePool borrow tests', async function (){
        let multiSign = await multiSignature.new([accounts[0],accounts[1],accounts[2],accounts[3],accounts[4]],3)
        let phx = await PHXCoin.new();
        let stakepool = await stakePoolCon.new(multiSign.address);
        let pptCoin = await PPTCoin.new(multiSign.address);
        let factory = await testLeverageFactory.new()
        await factory.createStakePool(stakepool.address,pptCoin.address,multiSign.address,"PPTA","PPTA",phx.address,1e5)
        let newToken = await factory.newContract();
        stakepool = await stakePoolCon.at(newToken);
//        fptCoin.setManager(stakepool.address);
        let addr = await stakepool.getPPTCoinAddress();
        console.log("getPPTCoinAddress : ",addr);
        addr = await stakepool.poolToken();
        console.log("poolToken : ",addr);
        let interest = await stakepool.interestRate();
        console.log("interestRate : ",interest.toNumber());
        await phx.mint(accounts[0],"1000000000000000000");
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        await stakepool.borrow("1000000000000000000");
        let balance = await phx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await phx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await phx.mint(accounts[0],"1000000000000000000");
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        await stakepool.borrowAndInterest("1000000000000000000");
        balance = await phx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await phx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await phx.mint(accounts[0],"1000000000000000000");
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.repayAndInterest("1000000000000000000"); 
        balance = await phx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await phx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await phx.mint(accounts[0],"1000000000000000000");
        await phx.approve(stakepool.address,"1000000000000000000");
        await stakepool.repay("1000000000000000000",false); 
        balance = await phx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await phx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
    });
});