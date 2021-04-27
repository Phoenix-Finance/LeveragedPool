pragma solidity =0.5.16;
import "./rebaseTokenData.sol";
import "../modules/SafeMath.sol";
contract rebaseToken is rebaseTokenData {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    /**
     * @dev Returns the amount of tokens in existence.
     */
    constructor () public{
    }
    function initialize() public{
        versionUpdater.initialize();
        Erc20InfoList.push(Erc20Info(0,rebaseDecimal,0));
        decimals = 18;
    }
    function update() public onlyOwner versionUpdate(){
    }
    function newErc20(uint256 leftAmount) external addressPermissionAllowed(msg.sender,allowNewErc20){
        Erc20InfoList[Erc20InfoList.length-1].leftAmount = leftAmount;
        Erc20InfoList.push(Erc20Info(0,rebaseDecimal,0));
    }
    function getErc20Info() internal view returns(Erc20Info memory){
        return Erc20InfoList[Erc20InfoList.length-1];
    }
    function totalSupply() external view returns (uint256){
        Erc20Info memory info = getErc20Info();
        return info._totalSupply*info.rebaseRatio/rebaseDecimal;
    }
  /**
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string memory _name, string memory _symbol,address token)
        public
        onlyOwner
    {
        //check parameter in ico minter contract
        name = _name;
        symbol = _symbol;
        leftToken = token;
    }
    function getRedeemAmount(address account)public view returns(uint256){
        uint256 len = Erc20InfoList.length-1;
        uint amount = 0;
        for (uint256 i=userBeginRound[account];i<len;i++){
            Erc20Info storage info = Erc20InfoList[i];
            if(info._totalSupply>0){
                amount = amount.add(info.leftAmount.mul(info.balances[account])/info._totalSupply);
            }
        }
        return amount;
    }
    function redeemAmount() public {
        uint256 amount = getRedeemAmount(msg.sender);
        if(amount > 0){
            _redeem(msg.sender,leftToken,amount);
        }
        userBeginRound[msg.sender] = Erc20InfoList.length-1;
    }
    function calRebaseRatio(uint256 newTotalSupply) public addressPermissionAllowed(msg.sender,allowRebalance) {
        Erc20Info storage info = Erc20InfoList[Erc20InfoList.length-1];
        if (info._totalSupply > 0){
            info.rebaseRatio = newTotalSupply.mul(rebaseDecimal)/info._totalSupply;
        }
    }
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256){
        Erc20Info storage info = Erc20InfoList[Erc20InfoList.length-1];
        return Erc20InfoList[Erc20InfoList.length-1].balances[account]*info.rebaseRatio/rebaseDecimal;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
    public
    returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
    public
    returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    function burn(address account,uint256 amount) public addressPermissionAllowed(msg.sender,allowBurn) returns (bool){
        _burn(account, amount);
        return true;
    }
    function mint(address account,uint256 amount) public addressPermissionAllowed(msg.sender,allowMint) returns (bool){
        _mint(account,amount);
        return true;
    }
    /**
     * @dev add `recipient`'s balance to iterable mapping balances.
     */
    function _addBalance(Erc20Info storage info,address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        info.balances[recipient] = info.balances[recipient].add(amount);
    }
    /**
     * @dev add `recipient`'s balance to iterable mapping balances.
     */
    function _subBalance(Erc20Info storage info,address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        info.balances[recipient] = info.balances[recipient].sub(amount);
    }
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        Erc20Info storage info = Erc20InfoList[Erc20InfoList.length-1];
        uint256 realAmount = amount.mul(rebaseDecimal)/info.rebaseRatio;
        _subBalance(info,sender,realAmount);
        _addBalance(info,recipient,realAmount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        Erc20Info storage info = Erc20InfoList[Erc20InfoList.length-1];
        uint256 realAmount = amount.mul(rebaseDecimal)/info.rebaseRatio;
        info._totalSupply = info._totalSupply.add(realAmount);
        _addBalance(info,account,realAmount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        Erc20Info storage info = Erc20InfoList[Erc20InfoList.length-1];
        uint256 realAmount = amount.mul(rebaseDecimal)/info.rebaseRatio;
        _subBalance(info,account,realAmount);
        info._totalSupply = info._totalSupply.sub(realAmount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
        /**
     * @dev An auxiliary foundation which transter amount stake coins to recieptor.
     * @param recieptor recieptor recieptor's account.
     * @param stakeCoin stake address
     * @param amount redeem amount.
     */
    function _redeem(address payable recieptor,address stakeCoin,uint256 amount) internal{
        if (stakeCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 token = IERC20(stakeCoin);
            token.safeTransfer(recieptor,amount);
        }
        emit Redeem(recieptor,stakeCoin,amount);
    }
}
