const stakePool = artifacts.require("stakePool");
const stakePoolProxy = artifacts.require("stakePoolProxy");
const FPTCoin = artifacts.require("FPTCoin");
contract('stakePool', function (accounts){
    it('stakePool normal tests', async function (){
        let fptCoin = await FPTCoin.new("FPT_stake");
        let fnx = await FPTCoin.new("FNX");
        let stakepool = await stakePool.new();
        await stakepool.setPoolInfo(fptCoin.address,fnx.address,50);
        let addr = await stakepool.getFPTCoinAddress();
        console.log("getFPTCoinAddress : ",addr);
        addr = await stakepool.poolToken();
        console.log("poolToken : ",addr);
        let interest = await stakepool.interestRate();
        console.log("interestRate : ",interest.toNumber());
        interest = await stakepool.poolBalance();
        console.log("poolBalance : ",interest.toNumber());
        interest = await stakepool.FPTTotalSuply();
        console.log("FPTTotalSuply : ",interest.toNumber());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toNumber());
    });
    it('stakePool stake tests', async function (){
        let fptCoin = await FPTCoin.new("FPT_stake");
        await fptCoin.setTimeLimitation(0);
        let fnx = await FPTCoin.new("FNX");
        let stakepool = await stakePool.new();
        fptCoin.setManager(stakepool.address);
        await stakepool.setPoolInfo(fptCoin.address,fnx.address,50);
        let addr = await stakepool.getFPTCoinAddress();
        console.log("getFPTCoinAddress : ",addr);
        addr = await stakepool.poolToken();
        console.log("poolToken : ",addr);
        let interest = await stakepool.interestRate();
        console.log("interestRate : ",interest.toNumber());
        await fnx.setManager(accounts[0]);
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        for(var i=0;i<50;i++){
            await fptCoin.setTimeLimitation(0);
        }
        interest = await fnx.balanceOf(accounts[0]);
        console.log("poolBalance : ",interest.toString());
        interest = await stakepool.poolBalance();
        console.log("poolBalance : ",interest.toString());
        interest = await stakepool.FPTTotalSuply();
        console.log("FPTTotalSuply : ",interest.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await stakepool.unstake("1000000000000000000");
        interest = await fnx.balanceOf(accounts[0]);
        console.log("poolBalance : ",interest.toString());
        interest = await stakepool.poolBalance();
        console.log("poolBalance : ",interest.toString());
        interest = await stakepool.FPTTotalSuply();
        console.log("FPTTotalSuply : ",interest.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
    });
    it('stakePool borrow tests', async function (){
        let fptCoin = await FPTCoin.new("FPT_stake");
        await fptCoin.setTimeLimitation(0);
        let fnx = await FPTCoin.new("FNX");
        let stakepool = await stakePool.new();
        fptCoin.setManager(stakepool.address);
        await stakepool.setPoolInfo(fptCoin.address,fnx.address,5e5);
        let addr = await stakepool.getFPTCoinAddress();
        console.log("getFPTCoinAddress : ",addr);
        addr = await stakepool.poolToken();
        console.log("poolToken : ",addr);
        let interest = await stakepool.interestRate();
        console.log("interestRate : ",interest.toNumber());
        await fnx.setManager(accounts[0]);
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        await stakepool.borrow("1000000000000000000");
        let balance = await fnx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await fnx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        await stakepool.borrowAndInterest("1000000000000000000");
        balance = await fnx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await fnx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.repayAndInterest("1000000000000000000"); 
        balance = await fnx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await fnx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.repay("1000000000000000000"); 
        balance = await fnx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await fnx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
    });
    it('IStakePool borrow tests', async function (){
        let fptCoin = await FPTCoin.new("FPT_stake");
        await fptCoin.setTimeLimitation(0);
        let fnx = await FPTCoin.new("FNX");
        let stakeimple = await stakePool.new();
        let stakepool = await stakePoolProxy.new(stakeimple.address,fnx.address,fptCoin.address,"FPT_stake",5e5);
//        fptCoin.setManager(stakepool.address);
        let addr = await stakepool.getFPTCoinAddress();
        console.log("getFPTCoinAddress : ",addr);
        addr = await stakepool.poolToken();
        console.log("poolToken : ",addr);
        let interest = await stakepool.interestRate();
        console.log("interestRate : ",interest.toNumber());
        await fnx.setManager(accounts[0]);
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        await stakepool.borrow("1000000000000000000");
        let balance = await fnx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await fnx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.stake("1000000000000000000");
        await stakepool.borrowAndInterest("1000000000000000000");
        balance = await fnx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await fnx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.repayAndInterest("1000000000000000000"); 
        balance = await fnx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await fnx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
        await fnx.mint(accounts[0],"1000000000000000000");
        await fnx.approve(stakepool.address,"1000000000000000000");
        await stakepool.repay("1000000000000000000"); 
        balance = await fnx.balanceOf(accounts[0]);
        console.log("balance : ",balance.toString());
        balance = await fnx.balanceOf(stakepool.address);
        console.log("balance : ",balance.toString());
        interest = await stakepool.tokenNetworth();
        console.log("tokenNetworth : ",interest.toString());
    });
});