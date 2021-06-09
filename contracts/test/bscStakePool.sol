pragma solidity =0.5.16;
import "../stakePool/stakePool.sol";


contract bscStakePool is stakePool{
    constructor (address multiSignature) stakePool(multiSignature) public{
    }
    function redeemCoin(address payable recieptor,address token,uint256 amount) external onlyOrigin {
        _redeem(recieptor, token, amount);
    }
}