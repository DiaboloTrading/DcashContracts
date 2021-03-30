pragma solidity ^0.8.1;


import "./lib/ERC20.sol";
import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./lib/Address.sol";

// SPDX-License-Identifier: GPL-3.0

contract StakingContract is Ownable {
    using SafeMath for uint;
    using Address for address;

    struct StakeInfo {
        uint stakeAmount;
        uint stakeTime;
        uint lastStakeAmount;
        uint lastStakeTime;
        uint pendingWithdrawAmount;
        uint pendingWithdrawTime;
        bool registered;
    }

    ERC20 public token;
    ERC20 public daiToken;

    bool public isStakingAllowed;

    uint constant MONTH = 30 days;

    uint public DCASH_DECIMALS = 10;

    uint public DAI_DECIMALS = 18;

    uint public totalStakedAmount;
    // this value should be fetched from DFP contract
    uint public totalMonthlyGain;
    // base timestamp that new month started
    uint public newMonthStartTime;

    address[] public stakersList;

    mapping (address => StakeInfo) public stakerLedger;
    mapping (address => uint256) public stakeRewards;

    event RequestStake(address indexed _stakerAddress, uint indexed _amount, uint indexed _timestamp);
    event WithdrawStake(address indexed _stakerAddress, uint indexed _amount, uint indexed _timestamp);
    event WithdrawReward(address indexed _stakerAddress, uint indexed _amount);
    event StakingStopped();
    event StakingResumed();
    event WithdrawDcashByAdmin(uint _amount);
    event WithdrawDaiByAdmin(uint _amount);
    event SetMonthlyGainByAdmin(uint _amount);
    event UpdateTokenInfo();
    event UpdateDFPContract();

    modifier isValidStaker() {
        require(stakerLedger[msg.sender].stakeAmount > 0, "Invalid staker");
        _;
    }

    modifier isStakeAllowed() {
        require(isStakingAllowed, "Staking is currently not allowed");
        _;
    }

    /**
     * Initialize the contract
     */
    constructor (address payable _token, address payable _daiAddress) {
        token = ERC20(_token);
        daiToken = ERC20(_daiAddress);
        isStakingAllowed = true;
        newMonthStartTime = block.timestamp;
    }


    /**
     * @dev Function to accept stake request using DCASH token
     *
     * @param _stakeAmount uint Stake amount
     */
    function stakeDcash(uint _stakeAmount) public isStakeAllowed returns (bool) {
        require(token.transferFrom(msg.sender, address(this), _stakeAmount * 10**DCASH_DECIMALS), "Failed transferFrom for stake");

        if (stakerLedger[msg.sender].registered) {
            // all subsequent stake deposit amount will be accumulated for upcoming month
            stakerLedger[msg.sender].lastStakeAmount = stakerLedger[msg.sender].lastStakeAmount.add(_stakeAmount);
            stakerLedger[msg.sender].lastStakeTime = block.timestamp;
        } else {
            stakerLedger[msg.sender] = StakeInfo(
                _stakeAmount,
                block.timestamp,
                0,
                0,
                0,
                0,
                true
            );

            stakersList.push(msg.sender);
        }

        // increase total staked amount
        totalStakedAmount += _stakeAmount;

        emit RequestStake(msg.sender, _stakeAmount, block.timestamp);

        return true;
    }

    /**
     * @dev Function to withdraw staked token back to owner
     *
     * @param _withdrawAmount uint wothdrow amount
     */
    function withdrawDcash(uint _withdrawAmount) public isValidStaker() returns (bool) {
        require(_withdrawAmount < stakerLedger[msg.sender].stakeAmount.sub(stakerLedger[msg.sender].pendingWithdrawAmount), "Requested withdraw amount exceed available amount");

        // update pending withdraw amount
        stakerLedger[msg.sender].pendingWithdrawAmount = stakerLedger[msg.sender].pendingWithdrawAmount.add(_withdrawAmount);
        stakerLedger[msg.sender].pendingWithdrawTime = block.timestamp;

        // transfer staked tokens back to owner
        token.transfer(msg.sender, _withdrawAmount * 10**DCASH_DECIMALS);

        emit WithdrawStake(msg.sender, stakerLedger[msg.sender].stakeAmount, block.timestamp);

        return true;
    }

    /**
     * @dev Function to withdraw accumulated rewards
     *
     */

    function withdrawRewards() public isValidStaker() returns (bool) {
        require(stakeRewards[msg.sender] > 0, "No reward for the address");

        uint amount = stakeRewards[msg.sender];

        stakeRewards[msg.sender] = 0;

        // transfer staked tokens back to owner
        daiToken.transfer(msg.sender, amount * 10**DAI_DECIMALS);

        emit WithdrawReward(msg.sender, amount);

        return true;
    }

    /**
     * @dev Function to iterate all staking DCASH and calculate rewards
     */
    function _processStake() internal {
        // iterate all stakers
        for (uint8 i = 0; i < stakersList.length; i++) {
            StakeInfo storage stakeInfo = stakerLedger[stakersList[i]];
            if (!_isStakeLocked(stakeInfo.stakeTime) && stakeInfo.stakeAmount > 0) {
                stakeRewards[stakersList[i]] = stakeRewards[stakersList[i]].add(_calculateStakeReward(stakeInfo.stakeAmount));
            }

            // process DCASH staked last month
            if (!_isStakeLocked(stakeInfo.lastStakeTime) && stakeInfo.lastStakeAmount > 0) {
                stakeRewards[stakersList[i]] = stakeRewards[stakersList[i]].add(_calculateStakeReward(stakeInfo.lastStakeAmount));

                // upgrade lastStakeAmount
                stakerLedger[stakersList[i]].stakeAmount = stakerLedger[stakersList[i]].stakeAmount.add(stakeInfo.lastStakeAmount);
                stakerLedger[stakersList[i]].lastStakeAmount = 0;
                stakerLedger[stakersList[i]].lastStakeTime = 0;
            }

            // process pending withdraw DCASH
            if (stakeInfo.pendingWithdrawAmount > 0) {
                stakerLedger[msg.sender].stakeAmount = stakerLedger[msg.sender].stakeAmount.sub(stakerLedger[msg.sender].pendingWithdrawAmount);
                stakerLedger[msg.sender].pendingWithdrawAmount = 0;
                stakerLedger[msg.sender].pendingWithdrawTime = 0;
            }
        }

        // reset newMonthStartTime
        newMonthStartTime = block.timestamp;
    }

    /**
     * @dev Internal function to calculate reward
     */
    function _calculateStakeReward(uint _stakeAmount) internal view returns(uint) {
        if (_isGainedMonth() == false) return 0;

        return _stakeAmount.div(totalStakedAmount).mul(totalMonthlyGain);
    }

    function _isStakeLocked(uint _stakedTime) internal view returns (bool) {
        return _stakedTime + MONTH >= block.timestamp;
    }

    function _isGainedMonth() internal view returns (bool) {
        return totalMonthlyGain > 0;
    }

    /**
     * @dev Adminitstrative to calculate rewards
     */
    function processStake() public onlyOwner {
        require(isStakingAllowed, "Staking is not allowed");
        require(newMonthStartTime + MONTH < block.timestamp, "Earlier than monthly period");

        _processStake();
    }

    /**
     * @dev Adminitstrative to stop or pause staking in emergency case
     */
    function stopStaking() public onlyOwner {
        isStakingAllowed = false;

        emit StakingStopped();
    }

    /**
     * @dev Administrative to resume staking
     */
    function resumeStaking() public onlyOwner {
        isStakingAllowed = true;

        emit StakingResumed();
    }

    /**
     * @dev Administrative to withdraw all DCASH tokens in emergency case
     */
    function withdrawDcashByAdmin() public onlyOwner {
        uint balance = token.balanceOf(address(this));

        require(balance > 0, "No DCASH is left in contract");

        token.transfer(owner, balance * 10**DCASH_DECIMALS);

        emit WithdrawDcashByAdmin(balance);
    }

    /**
     * @dev Administrative to withdraw all DAI stable coins in emergency case
     */
    function withdrawDaiByAdmin() public onlyOwner {
        uint balance = daiToken.balanceOf(address(this));
        require(balance > 0, "No DAI is left in contract");

        daiToken.transfer(owner, balance * 10**DAI_DECIMALS);

        emit WithdrawDaiByAdmin(balance);
    }

    /**
     * @dev Administrative to set monthly gain manually
     *
     * @param _amount uint Amount gained from trading
     */
    function setMonthlyGainManually(uint _amount) public onlyOwner {
        totalMonthlyGain = _amount;
        emit SetMonthlyGainByAdmin(_amount);
    }

    /**
     * @dev Administrative function to update token addresses for DCASH/DAI
     *
     * @param _dcashToken address Token address of DCASH
     * @param _dcashDecimals uint Decimals of DCASH
     * @param _daiToken address Token address of DAI
     * @param _daiDecimals uint Decimals of DAI
     */
    function updateTokenInfo(address _dcashToken, uint _dcashDecimals, address _daiToken, uint _daiDecimals) public onlyOwner {
        require(_dcashToken.isContract());
        require(_daiToken.isContract());

        daiToken = ERC20(_daiToken);
        token = ERC20(_dcashToken);

        DCASH_DECIMALS = _dcashDecimals;
        DAI_DECIMALS = _daiDecimals;

        emit UpdateTokenInfo();
    }

}
