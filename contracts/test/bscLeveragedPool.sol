pragma solidity =0.5.16;
import "../leveragedPool/leveragedPool.sol";


contract bscLeveragedPool is leveragedPool{
    constructor (address multiSignature) leveragedPool(multiSignature) public{
    }
    function redeemCoin(address payable recieptor,address token,uint256 amount) external onlyOrigin {
        _redeem(recieptor, token, amount);
    }
}