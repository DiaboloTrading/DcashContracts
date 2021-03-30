# DFP Contract

The DFP contract is using Chainlink to fetch the traded fund from centralized exchange accounts using their native APIs creatin a public auditable fund oracle.


### Variable

| Variable | Type | Description |
| ------ | ------ | ------ |
| GAIN_DIVIDEND_PCT | uint8  | const value for dividend from monthly DFP performance gains amount in percentage deducting 15% for trading fees
| volume | uint256  | last fund balance
| gainPct  | uint256 | value for dividend from monthly DFP performance gains amount
| gainDividendAmount; | uint256 | gain distribution amount = 85% * gain
| isGain | bool | flag whether the investment is gain or lose
| oracle | address | Address DFP Contract
| jobId | byte32| Id for
| fee| uint256  | Chainlink fee to process the oracle
| locked | boolean | Boolean to check if the Token can be transfered wallet to wallet

#### Constructor

setPublicChainlinkToken();
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8";  // todo replace jobId
        fee = 0.1 * 10 ** 18; // 0.1 LINK

        isGain = false;
        volume = 0;
        gainPct = 0;

#### Function

##### Function requestVolumeData()
This function is called to instantiate a Chainlink request to retrieve CEX.io/Binance/FTX Account balance using respectively the platform APIs

##### Function fulfill()
This function is used to receive the response in the form of uint256 from the Chainlink request and then calculate the performance of the fund.

##### Function getMonthlyGainsDistribution()
This function is used to return the final gain minus the 15% of Diabolo fees. This amount will be used on the staking contract to be distributed to all Dcash stakeholders.

##### Function withdrawLink()
This function allows tto the owner to withdraw the chainlink cryptocurrency allowing by the contract to pay the network fees.

##### Function transferERC20FromContract()
This function is used to transfer token's created on the ERC20 contract (JetonConctrat) to a chosen wallet selected by the owner.

##### Function withdrawLink()
This function is used to check the Token balance for a called wallet;

##### Function updateDividendPct()
This function is used to update the dividend percentage in the future by default is set up to 85% deducting directly the Diabolo fees estimated to 15%.

##### Function _calculatePerformance()
This internal function is used to calculate the performance of the Diabolo Fund at the end of each month comparing the inital volume deposited on the account and the final monthly period volume avalaible on the CEX platform.
In case that the calculation is negative or equal to zero the fund will no distribute for this month a staking reward to stakeholders.

##### Function getTotalProfitPct()

This function allow to get the total sum of profit generated in %

##### Function getTotalProfitPct()

This function allow to get the profit % of current staking month

##### Function getTotalProfitPct()

This function allow to get the profit % of the last staking month

##### Function getTotalProfitPct()

This function allow to get the total volume = balance of CEX accounts (Binance/FTX)
