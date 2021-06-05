pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "../proxyModules/proxyOperator.sol";
import "../proxyModules/AddressWhiteList.sol";
import "../modules/ReentrancyGuard.sol";
import "../proxyModules/versionUpdater.sol";
import "../modules/safeTransfer.sol";
/**
 * @title new Phoenix Options Pool token mine pool.
 * @dev A smart-contract which distribute some mine coins when you stake some FPT-A and FPT-B coins.
 *      Users who both stake some FPT-A and FPT-B coins will get more bonus in mine pool.
 *      Users who Lock FPT-B coins will get several times than normal miners.
 */
 interface IAccelerator {
    function getAcceleratedBalance(address account)external returns(uint256,uint64); 
}
contract acceleratedMinePoolData is versionUpdater,proxyOperator,Halt,AddressWhiteList,safeTransfer,ReentrancyGuard {
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;

    //The max loop when user does nothing to this pool for long long time .
    uint256 constant internal _maxLoop = 120;

    // FPT-A address
    address internal _FPT;
    IAccelerator accelerator;
    uint256 acceleratorStart;
    uint256 acceleratorPeriod;
    struct userInfo {
        //user's FPT staked balance
        uint256 fptBalance;
        //User's mine distribution.You can get base mine proportion by your distribution divided by total distribution.
        uint256 distribution;
        uint256 maxPeriodID;
        //User's settled mine coin balance.
        mapping(address=>uint256) minerBalances;
        //User's latest settled distribution net worth.
        mapping(address=>uint256) minerOrigins;
        //user's latest settlement period for each token.
        mapping(address=>uint256) settlePeriod;
    }
    struct tokenMineInfo {
        //mine distribution amount
        uint256 mineAmount;
        //mine distribution time interval
        uint256 mineInterval;
        //mine distribution first period
        uint256 startPeriod;
        //mine coin latest settlement time
        uint256 latestSettleTime;
        // total mine distribution till latest settlement time.
        uint256 totalMinedCoin;
        //latest distribution net worth;
        uint256 minedNetWorth;
        //period latest distribution net worth;
        mapping(uint256=>uint256) periodMinedNetWorth;
    }

    //User's staking and mining info.
    mapping(address=>userInfo) internal userInfoMap;
    //each mine coin's mining info.
    mapping(address=>tokenMineInfo) internal mineInfoMap;
    //total weight distribution which is used to calculate total mined amount.
    mapping(uint256=>uint256) internal weightDistributionMap;
    //total Distribution
    uint256 internal totalDistribution;
    uint256 public startTime;


    /**
     * @dev Emitted when `account` stake `amount` FPT-A coin.
     */
    event StakeFPTA(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` unstake `amount` FPT-A coin.
     */
    event UnstakeFPTA(address indexed account,uint256 amount);

    /**
     * @dev Emitted when `account` redeem `value` mineCoins.
     */
    event RedeemMineCoin(address indexed account, address indexed mineCoin, uint256 value);

}