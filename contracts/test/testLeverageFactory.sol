pragma solidity =0.5.16;
import "../rebaseToken/IRebaseToken.sol";
import "../proxy/phxProxy.sol";
import "../proxyModules/proxyOperator.sol";
import "../PPTCoin/IPPTCoin.sol";
import "../stakePool/IStakePool.sol";
contract testLeverageFactory {
    address public newContract;
    function createRebaseToken(address implement,address multsign,string memory name,string memory symbol,address token)public returns(address){
        phxProxy newProxy = new phxProxy(implement,multsign);
        newContract = address(newProxy);
        IRebaseToken rebaseToken = IRebaseToken(newContract);
        proxyOperator(newContract).setManager(msg.sender);
        rebaseToken.changeTokenName(name,symbol,token);
        rebaseToken.setTimeLimitation(1);
        return newContract;
    }
    function createStakePool(address implement,address pptImplement,address multsign,string memory name,string memory symbol,address token,uint64 _interestrate)public returns(address){
        address pptCoin = createPPTCoin(pptImplement,multsign,name,symbol);
        phxProxy newProxy = new phxProxy(implement,multsign);
        newContract = address(newProxy);
        IStakePool(newContract).setPoolInfo(pptCoin,token,_interestrate);
        IStakePool(newContract).modifyPermission(msg.sender,0xffffffff);
        proxyOperator(pptCoin).setManager(newContract);
        return newContract;
    }
    function createPPTCoin(address implement,address multsign,string memory name,string memory symbol)internal returns(address){
        phxProxy newProxy = new phxProxy(implement,multsign);
        IPPTCoin(address(newProxy)).changeTokenName(name,symbol,18);
        return address(newProxy);
    }
}