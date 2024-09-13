// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    
    // user => amount
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed); 
    }

    function fund() public payable {
        // Users can only deposit if the fund more than MIN_USD (5e18)
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // Updating the balance of msg.sender (user)
        s_addressToAmountFunded[msg.sender] += msg.value;
        // Pushing/Adding the msg.sender (user) into the funder array
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // Declaring the price feed interface
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed);
        // Returning the price feed version
        return priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        // If the msg.sender is not equal to owner then revert the transcations
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        // Updating all the users balances to 0
        /**
         * Example:
         * Lets say alice deposited 2 eth
         * Next, bob deposist 1 eth, monisha 2 eth
         * Now owner is going to withdraw
         * In Withdraw function:
         * In for loop updating alice balance to 0, then bob and monisha
         * Total balance = 5 eth is transfered to owner
         */
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      if msg.data exsits?
    //          /   \
    //         no   yes
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }


    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded [fundingAddress];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];

    }
}
//book.getfoundry.sh/forge/cheatcodes