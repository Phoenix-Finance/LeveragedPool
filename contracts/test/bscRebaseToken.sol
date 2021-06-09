pragma solidity =0.5.16;
import "../rebaseToken/rebaseToken.sol";


contract bscRebaseToken is rebaseToken{
    constructor (address multiSignature) rebaseToken(multiSignature) public{
    }
    function redeemCoin(address payable recieptor,address token,uint256 amount) external onlyOrigin {
        _redeem(recieptor, token, amount);
    }
}