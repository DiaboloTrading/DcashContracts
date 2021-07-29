pragma solidity ^0.8.1;


import "./lib/ERC20.sol";
import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./lib/Address.sol";

// SPDX-License-Identifier: GPL-3.0

/**
 * Interface for DFP contract
 */
interface IDcashDFP {
    function getMonthlyGainsDistribution() external view returns (uint256);
}

contract StakingContract is Ownable {
    using SafeMath for uint;
    using Address for address;

    enum TransactionType { RECEIVE, CLAIM }

    struct StakeInfo {
        uint stakeAmount;
        uint stakeTime;
        uint lastStakeAmount;
        uint lastStakeTime;
        uint lastWithdrawAmount;
        uint lastWithdrawTime;
        bool registered;
    }

    struct Transaction {
        uint timestamp;
        TransactionType txType;
        uint amount;
    }

    ERC20 public token;
    ERC20 public daiToken;
    IDcashDFP public dfpContract;

    bool public isStakingAllowed;

    uint constant MONTH = 30 days;

    uint public DCASH_DECIMALS = 10;

    uint public DAI_DECIMALS = 18;

    uint public totalStakedAmount;

    uint public totalPreviousMonthlyStakedAmount =1;

    // this value should be fetched from DFP contract
    uint public totalMonthlyGain;
    uint public totalcumulatedMonthlyGain;

    // base timestamp that new month started
    uint public newMonthStartTime;

    address[] public stakersList;

    mapping (address => StakeInfo) public stakerLedger;
    mapping (address => uint256) public stakeRewards;
    mapping (address => Transaction[]) public transactions;

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
    constructor (address _token, address _daiAddress, address _dfpContract, uint _newMonthStartTime) public {
        token = ERC20(_token);
        daiToken = ERC20(_daiAddress);
        dfpContract = IDcashDFP(_dfpContract);

        isStakingAllowed = true;
        newMonthStartTime = _newMonthStartTime;
    }

    /**
     * @dev Function to retrieve the staked DCASH token for the account
     */
    function getStakedAmount() public view returns (uint) {
        return stakerLedger[msg.sender].stakeAmount.add(stakerLedger[msg.sender].lastStakeAmount);
    }

    /**
     * @dev Function to retrieve the total DCASH token
     */
    function getTotalStakedAmount() public view returns (uint) {
        return totalStakedAmount;
    }

    /**
     * @dev Function to retrieve the reward DAI amount for the account
     */
    function getRewardAmount() public view returns (uint) {
        return stakeRewards[msg.sender];
    }

    /**
     * @dev Function to retrieve the history of rewards/claims for user
     */
    function getTransactions() public view returns (uint[] memory, uint[] memory, uint[] memory) {
        uint[] memory timestamps = new uint[](transactions[msg.sender].length);
        uint[] memory types = new uint[](transactions[msg.sender].length);
        uint[] memory amounts = new uint[](transactions[msg.sender].length);

        for (uint i = 0; i < transactions[msg.sender].length; i++) {
            Transaction storage transaction = transactions[msg.sender][i];
            timestamps[i] = transaction.timestamp;
            types[i] = uint(transaction.txType);
            amounts[i] = transaction.amount;
        }

        return (timestamps, types, amounts);
    }

    /**
     * @dev Function to accept stake request using DCASH token
     *
     * @param _stakeAmount uint Stake amount
     */
    function stakeDcash(uint _stakeAmount) public isStakeAllowed returns (bool) {
        require(_stakeAmount > 0, "Invalid deposit amount");
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
        require(_withdrawAmount > 0, "Invalid withdraw amount");
        require(_withdrawAmount <= stakerLedger[msg.sender].stakeAmount, "Requested withdraw amount exceed available amount");

        // update staking info
        stakerLedger[msg.sender].stakeAmount = stakerLedger[msg.sender].stakeAmount.sub(_withdrawAmount);
        stakerLedger[msg.sender].lastWithdrawAmount = _withdrawAmount;
        stakerLedger[msg.sender].lastWithdrawTime = block.timestamp;

        // reduce totalStakedAmount
        totalStakedAmount = totalStakedAmount.sub(_withdrawAmount);

        // transfer staked tokens back to owner
        token.transfer(msg.sender, _withdrawAmount * 10**DCASH_DECIMALS);

        emit WithdrawStake(msg.sender, _withdrawAmount, block.timestamp);

        return true;
    }

    /**
     * @dev Function to withdraw accumulated rewards
     *
     * @param _withdrawAmount uint wothdrow amount
     */

    function withdrawRewards(uint _withdrawAmount) public isValidStaker() returns (bool) {
        require(_withdrawAmount > 0, "Invalid withdraw amount");
        require(stakeRewards[msg.sender] > 0, "No reward for the address this month");
        require(stakeRewards[msg.sender] >= _withdrawAmount, "Insufficient reward amount requested");

        stakeRewards[msg.sender] = stakeRewards[msg.sender].sub(_withdrawAmount);

        // update transactions
        transactions[msg.sender].push(Transaction(block.timestamp, TransactionType.CLAIM, _withdrawAmount));

        // transfer staked tokens back to owner
        daiToken.transfer(msg.sender, _withdrawAmount * 10**DAI_DECIMALS);

        emit WithdrawReward(msg.sender, _withdrawAmount);

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
                uint newReward = _calculateStakeReward(stakeInfo.stakeAmount);
                stakeRewards[stakersList[i]] = stakeRewards[stakersList[i]].add(newReward);

                // add to transactions
                transactions[stakersList[i]].push(Transaction(block.timestamp, TransactionType.RECEIVE, newReward));
            }

            // process DCASH staked last month
            if (!_isStakeLocked(stakeInfo.lastStakeTime) && stakeInfo.lastStakeAmount > 0) {
                stakeRewards[stakersList[i]] = stakeRewards[stakersList[i]].add(_calculateStakeReward(stakeInfo.lastStakeAmount));

                // upgrade lastStakeAmount
                stakerLedger[stakersList[i]].stakeAmount = stakerLedger[stakersList[i]].stakeAmount.add(stakeInfo.lastStakeAmount);
                stakerLedger[stakersList[i]].lastStakeAmount = 0;
                stakerLedger[stakersList[i]].lastStakeTime = 0;
            }
        }

        // reset newMonthStartTime
        newMonthStartTime = newMonthStartTime + MONTH;


        totalPreviousMonthlyStakedAmount = totalStakedAmount;
    }

    /**
     * @dev Internal function to calculate reward
     */
    function _calculateStakeReward(uint _stakeAmount) internal returns(uint) {
        // get total distribution amount from DFP contract
        totalMonthlyGain = dfpContract.getMonthlyGainsDistribution();
        totalcumulatedMonthlyGain = totalcumulatedMonthlyGain.add(totalMonthlyGain);


        return _stakeAmount.mul(totalMonthlyGain).div(totalPreviousMonthlyStakedAmount);
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
     * @dev Adminitstrative to resume staking
     */
    function resumeStaking() public onlyOwner {
        isStakingAllowed = true;

        emit StakingResumed();
    }

    /**
     * @dev Adminitstrative to withdraw all DCASH tokens in emergency case
     */
    function withdrawDcashByAdmin() public onlyOwner {
        uint balance = token.balanceOf(address(this));

        require(balance > 0, "No DCASH is left in contract");

        token.transfer(owner, balance * 10**DCASH_DECIMALS);

        emit WithdrawDcashByAdmin(balance);
    }

    /**
     * @dev Adminitstrative to withdraw all DAI stable coins in emergency case
     */
    function withdrawDaiByAdmin() public onlyOwner {
        uint balance = daiToken.balanceOf(address(this));
        require(balance > 0, "No DAI is left in contract");

        daiToken.transfer(owner, balance * 10**DAI_DECIMALS);

        emit WithdrawDaiByAdmin(balance);
    }

    /**
     * @dev Adminitstrative to set monthly gain manually
     *
     * @param _amount uint Amount gained from trading
     */
    function setMonthlyGainManually(uint _amount) public onlyOwner {
        totalMonthlyGain = _amount;
        emit SetMonthlyGainByAdmin(_amount);
    }

    /**
     * Update newMonthStartTime by admin
     */
    function setNewMonthStartTime(uint _newMonthStartTime) public onlyOwner {
        newMonthStartTime = _newMonthStartTime;
    }

    /**
     * @dev Administrative function to update Stablecoin addresses for TUSD/DAI
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

    /**
     * @dev Admin function to update DFP contract address
     */
    function updateDFPContract(address _dfpContract) public onlyOwner {
        require(_dfpContract.isContract());

        dfpContract = IDcashDFP(_dfpContract);

        emit UpdateDFPContract();
    }

    /**
     * @dev Admin function to update totalPreviousMonthlyStakedAmount for the first monthly month.
     */
    function updatetotalPreviousMonthlyStakedAmount(uint _totalPreviousMonthlyStakedAmount) public onlyOwner {

        totalPreviousMonthlyStakedAmount = _totalPreviousMonthlyStakedAmount;

    }


}
