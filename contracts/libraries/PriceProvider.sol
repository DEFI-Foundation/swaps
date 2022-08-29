// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './IPriceProvider.sol';

contract PriceProvider is IPriceProvider, Ownable {
    AggregatorInterface public priceProvider;
    string private description;

    constructor (AggregatorInterface _priceProvider, string memory _description) {
        priceProvider = _priceProvider;
        description = _description;
    }

    function getPrice() external view override returns (uint256) {
        return uint256(priceProvider.latestAnswer());
    }

    function getDescription() external view override returns (string memory) {
        return description;
    }
}
