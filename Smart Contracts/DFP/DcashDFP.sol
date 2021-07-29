// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/access/Ownable.sol";

contract DcashDFP is ChainlinkClient, Ownable {
    using SafeMath for uint;
    using Address for address;

    // const value for dividend from monthly DFP performance gains amount
    uint8 public GAIN_DIVIDEND_PCT = 85;
    uint constant MONTH = 30 days;

    // latest fund balance
    uint256 public volume;
    // last month's balance
    uint256 public lastMonthVolume;

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
    string private adapterUrl;

    // history of gains %
    uint256[] private profitPctHistory;
    uint256 private totalProfit;

    // base timestamp that new month started
    uint public newMonthStartTime;

    // variable related with keeper
    address private keeperProxy;

    event UpdateKeeperProxy(address indexed _keeperProxy);
    event UpdateAdapterUrl();

    modifier onlyKeeperProxy() {
        require(msg.sender == owner() || msg.sender == keeperProxy, "Unauthorized access");
        _;
    }

    constructor(uint _newMonthStartTime, uint _lastMonthVolume) public {
        setPublicChainlinkToken();
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        adapterUrl = "http://167.99.136.158:8080/";

        isGain = false;
        volume = 0;
        gainPct = 0;
        lastMonthVolume = _lastMonthVolume;

        newMonthStartTime = _newMonthStartTime;
    }

    /**
     * Create a Chainlink request to retrieve CEX.io Account balance
     */
    function requestVolumeData() external onlyKeeperProxy returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        request.add("get", adapterUrl);

        // Sends the request
        request.add("path", "result");

        // Multiply the result by 1000000000000000000 to remove decimals
        request.addInt("times", 1);

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
     * Update total profit amount by admin
     */
    function setTotalProfitByAdmin(uint _totalProfit) public onlyOwner {
        totalProfit = _totalProfit;
    }

    /**
     * Update monthly dividend amount by admin
     */
    function setMonthlyGainsDistributionByAdmin(uint _monthlyDistribution) public onlyOwner {
        gainDividendAmount = _monthlyDistribution;
    }


    /**
     * Update volumn amount by admin
     */
    function setVolumnByAdmin(uint _volume) public onlyOwner {
        _calculatePerformance(_volume);
    }

    /**
     * Update current profit by admin
     */
    function setCurrentProfitByAdmin(uint _currentProfit) public onlyOwner {
        profitPctHistory.push(_currentProfit);
    }

    /**
     * Update newMonthStartTime by admin
     */
    function setNewMonthStartTime(uint _newMonthStartTime) public onlyOwner {
        newMonthStartTime = _newMonthStartTime;
    }

    /**
     * Update lastMonthVolume by admin
     */
    function setLastMonthVolume(uint _lastMonthVolume) public onlyOwner {
        lastMonthVolume = _lastMonthVolume;
    }

    /**
     * Update newMonthStartTime by admin
     */
    function setJobInfo(bytes32 _jobId, address _oracleAddress) public onlyOwner {
        jobId = _jobId;
        oracle = _oracleAddress;
    }

    /**
     * @dev Admin function to update KeeperProxy contract address
     */
    function updateKeeperProxy(address _keeperProxy) public onlyOwner {
        require(_keeperProxy.isContract());

        keeperProxy = _keeperProxy;

        emit UpdateKeeperProxy(_keeperProxy);
    }

    /**
     * Update adapterUrl by admin
     */
    function updateAdapterUrl(string memory _adapterUrl) public onlyOwner {
        adapterUrl = _adapterUrl;

        emit UpdateAdapterUrl();
    }

    /**
     * Internal function to calculate performance of DFP
     * @notice this will calculate performance only by 1 month
     */
    function _calculatePerformance(uint256 _volume) internal {
        if (newMonthStartTime + MONTH < block.timestamp) {
            if (_volume > lastMonthVolume) {
                isGain = true;
                gainPct = (_volume - lastMonthVolume).mul(100).div(lastMonthVolume);
                gainDividendAmount = (_volume - lastMonthVolume).mul(GAIN_DIVIDEND_PCT).div(100);
            } else {
                isGain = false;
                gainPct = 0;
                gainDividendAmount = 0;
            }

            profitPctHistory.push(gainPct);
            totalProfit = totalProfit.add(gainPct);

            // update new month balance
            lastMonthVolume = _volume - gainDividendAmount;

            // update new month timestamp
            newMonthStartTime = newMonthStartTime + MONTH;
        }

        volume = _volume;
    }
}