# FundMe Foundry Project

## Overview
FundMe is a Solidity smart contract that allows users to fund the contract and withdraw funds. It utilizes Chainlink's price feed to ensure that funders meet a minimum contribution in USD value.

## Project Structure
```
FundMe/
│── contracts/
│   ├── FundMe.sol
│   ├── PriceConverter.sol
│── script/
│── test/
│── foundry.toml
│── README.md
```

## Contracts

### `FundMe.sol`
This is the main contract that allows users to fund and withdraw ETH. It ensures that contributions meet a minimum USD threshold by integrating Chainlink's AggregatorV3Interface.

#### Features:
- Users can fund the contract with ETH.
- Minimum contribution enforced using Chainlink price feeds.
- Only the contract owner can withdraw funds.
- Uses `fallback()` and `receive()` functions to accept ETH transfers.

#### Code:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    fallback() external payable { fund(); }
    receive() external payable { fund(); }
}
```

### `PriceConverter.sol`
This is a library that provides conversion functions to get the price of ETH in USD and convert ETH amounts to their USD equivalent.

#### Features:
- Fetches ETH price from Chainlink price feed.
- Converts ETH amount to USD.



## Deployment (Foundry)
To deploy the contract using Foundry:

1. Install Foundry:
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Compile the contract:
   ```sh
   forge build
   ```

3. Run tests:
   ```sh
   forge test
   ```

4. Deploy the contract:
   ```sh
   forge create --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> src/FundMe.sol:FundMe --constructor-args <CHAINLINK_PRICE_FEED_ADDRESS>
   ```

## Testing
Foundry tests should be added in the `test/` directory to ensure the contract functions as expected.

---




