# Staking Diabolo Contract

The Diabolo Staking Contract is based on ERC20 standards with additionnal customized functions for management of the staking contract.


### Variable

| Variable | Type | Description |
| ------ | ------ | ------ |
| stakeAmount | uint | Amount staked in DCASH EC20 Token
| stakeTime | uint | Block timestamp registered when the staked amount is deposited on the contract
| lastStakeAmount | uint | Last stakeAmount staked on the contract
| totalStakedAmount | uint | Total staked amount on the contract
| lastStakeTime | uint | Last Block timestamp registered during the lastStakeAmount deposit
| pendingWithdrawAmount | uint | Pending stakeAmount claimed
| pendingWithdrawTime | uint | Pending withdraw process status
| registered | boolean | Status to check the registration of StakeInfo data
| isStakingAllowed | boolean | Status to check if the staking contract is paused or running
| totalMonthlyGain | uint | Total gain made bu the Dcash Staking Performance contract
| newMonthStartTime | uint | Upcomin staking month timestamp
| stakersList | list | List of all stakers addresses registered
| stakerLedger | mapping (address => StakeInfo) | Variable allowing to add an address approved with the respected amount
| stakeRewards | mapping (address --> uint256) | The amount of reward in DAI the contract handle
| mintingFinished| boolean | Boolean to check if the owner can mint new tokens
| isValidStaker | modifier | Boolean to check if the staker is registered with an amount of staking > 0
| isStakeAllowed | modifier | Boolean to check if the staker is allowed to deposit to interact with the staking contract to stake Dcash amount

#### Constructor
The constructor set the Dcash ERC20 contract address and the DAI contract address to be initialized.

#### Function

##### Function stakeDcash()
This function is called to stake DCASH ERC20 tokens. The function is checking if the staker is already registred in that case the deposited amount is cumulated to the existing stakes. In any case the staker is registered with the amount staked, the timestamp is eligible to be calculated for the upcoming month.

The deposited staking amount is then added to the totalStakedAmount of the entire contract.

##### Function withdrawDcash()
This function is used to withdraw Dcash staked amount by staker.

##### Function withdrawRewards()
This function is used to  claim the cumulated DAI rewards

##### Function _processStake()
This function allows to calculate the final rewards for all stakers for the ended month. A reset is done for the new eligible month.

##### Function _calculateStakeReward()
This function is used to calculate for each staker the DAI rewards if the Gain is positive. In case if it's negative or zero it will no be rewarded for this month indeed the Dcash team will pay the losses to not impact the stakers for this perdiod.

##### Function _isStakeLocked()
This function is used to check if the staking amount was not claimed before the end of the 30 days staking period.

##### Function _isGainedMonth()
This function is used to check if the DFP made a profit or losses.

##### Function stopStaking()
This function is used to pause the staking contract in case it's needed for any technical or security reasons.

##### Function withdrawDcashByAdmin()
This function provides a way to the admin to withdraw all Dcash in case of emergency.

##### Function withdrawDaiByAdmin()
This function provides a way to the admin to withdraw all DAI in case of emergency.

##### Function resumeStaking
This function provides a way to resume the staking contract called by the owner.

##### Function getStakedAmount
This function retrieves the staked DCASH token for the account

##### Function getRewardAmount
This function retrieves the the reward DAI amount for the account

##### Function getTransactions
This function retrieves the history of rewards/claims for user depending on their wallet address
