// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IPriceProvider {
    function getPrice() external view returns (uint256);

    function getDescription() external view returns (string memory);
}
