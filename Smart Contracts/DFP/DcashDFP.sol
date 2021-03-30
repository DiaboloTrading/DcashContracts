pragma solidity ^0.6.0;

import "./lib/ERC20.sol";
import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./lib/Address.sol";
import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract DcashDFP is ChainlinkClient, Ownable {
    using SafeMath for uint;

    // const value for dividend from monthly DFP performance gains amount
    uint8 public GAIN_DIVIDEND_PCT = 85;

    // last fund balance
    uint256 public volume;
    // nominated as a value multiplied by 100
    uint256 public gainPct;
    // gain distribution amount = 85% * gain
    uint256 public gainDividendAmount;
    // flag whether the investment is gain or lose
    bool public isGain;

    // variables related for DFP adapter
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // history of gains %
    uint256[] private profitPctHistory;
    uint256 private totalProfit;


    constructor() public {
        setPublicChainlinkToken();
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8";  // todo replace jobId
        fee = 0.1 * 10 ** 18; // 0.1 LINK

        isGain = false;
        volume = 0;
        gainPct = 0;
    }

    /**
     * Create a Chainlink request to retrieve CEX.io Account balance
     */
    function requestVolumeData() public onlyOwner returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        // call internal function
        _calculatePerformance(_volume);
    }

    /**
     * Get gain distribution amount
     */
    function getMonthlyGainsDistribution() external view returns (uint256) {
        return gainDividendAmount;
    }

    /**
     * Get total sum of profit %
     */
    function getTotalProfitPct() external view returns (uint256) {
        return totalProfit;
    }

    /**
     * Get profit % of current month
     */
    function getCurrentProfitPct() external view returns (uint256) {
        return profitPctHistory[profitPctHistory.length - 1];
    }

    /**
     * Get profit % of last month
     */
    function getLastProfitPct() external view returns (uint256) {
        return profitPctHistory[profitPctHistory.length - 2];
    }

    /**
     * Get total volume = balance of CEX account
     */
    function getCurrentFunds() external view returns (uint256) {
        return volume;
    }

    /**
     * Withdraw LINK from this contract by only admin
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * Update dividend % by admin
     */
    function updateDividendPct(uint8 _newPct) public onlyOwner {
        require(_newPct <= 100, "Invalid value");
        GAIN_DIVIDEND_PCT = _newPct;
    }

    /**
     * Internal function to calculate performance of DFP
     */
    function _calculatePerformance(uint256 _volume) internal {
        if (_volume > volume) {
            isGain = true;
            gainPct = (_volume - volume).mul(100).div(volume);
            gainDividendAmount = (_volume - volume).mul(GAIN_DIVIDEND_PCT).div(100);
        } else {
            isGain = false;
            gainPct = 0;
            gainDividendAmount = 0;
        }

        profitPctHistory.push(gainPct);
        totalProfit = totalProfit.add(gainPct);

        volume = _volume;
    }
}
