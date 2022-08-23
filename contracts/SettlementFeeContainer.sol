// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract SettlementFeeContainer is Ownable {
    string public description;

    using SafeERC20 for ERC20;
    bool public paused = false;
    address[] private swapPairsManagement;

    event PayLiquidationFee(address to, uint256 amount, address typeFeeToken);

    event DecommissionSC(
        address decommissionAssset,
        uint256 decommissionBalance,
        address decommissionBeneficiary
    );
    event AddSwapPairsManagement(address newPairAddress);
    event RemoveSwapPairsManagement(address toRemovePairAddress);
    event SetStateSC(bool state);

    constructor(string memory _description) {
        description = _description;
    }

    receive() external payable {}

    function payLiquidationFee(
        address to,
        uint256 amount,
        address typeFeeToken
    ) external onlyHighLevelAccess checkSCUnpaused {
        if (typeFeeToken == address(0)) {
            require(
                to != address(0),
                'Error on payLiquidationFee: cannot send liquidation fee to null address'
            );
            require(
                address(this).balance >= amount,
                'Error on payLiquidationFee: you are trying to unlock more fees than have been locked on the smart contract'
            );
            Address.sendValue(payable(to), amount);
        } else {
            require(
                to != address(0),
                'Error on payLiquidationFee: cannot send liquidation fee to null address'
            );
            require(
                ERC20(typeFeeToken).balanceOf(address(this)) >= amount,
                'Error on payLiquidationFee: you are trying to unlock more fees than have been locked on the smart contract'
            );
            ERC20(typeFeeToken).safeTransfer(to, amount);
        }
        emit PayLiquidationFee(to, amount, typeFeeToken);
    }

    function addSwapPairsManagement(address newPairAddress) external onlyOwner {
        require(
            !verifySwapPairsManagement(newPairAddress),
            'Error on addSwapPairsManagement: address to add already has swapManagement level access'
        );
        swapPairsManagement.push(newPairAddress);
        emit AddSwapPairsManagement(newPairAddress);
    }

    function removeSwapPairsManagement(address toDeleteAddress)
        external
        onlyOwner
    {
        require(
            verifySwapPairsManagement(toDeleteAddress),
            'Error on removeSwapPairsManagement: toDeleteAddress is not listed as swapManagement'
        );
        uint256 i;
        for (i = 0; i < swapPairsManagement.length; i++) {
            if (swapPairsManagement[i] == toDeleteAddress) {
                swapPairsManagement[i] = swapPairsManagement[
                    swapPairsManagement.length - 1
                ];
                swapPairsManagement.pop();
                emit RemoveSwapPairsManagement(toDeleteAddress);
                break;
            }
        }
    }

    function verifySwapPairsManagement(address toCheck)
        public
        view
        returns (bool isSwapManagement)
    {
        uint256 i;
        for (i = 0; i < swapPairsManagement.length; i++) {
            if (swapPairsManagement[i] == toCheck) {
                return true;
            }
        }
        return false;
    }

    modifier onlyHighLevelAccess() {
        require(
            (verifySwapPairsManagement(_msgSender())) ||
                (_msgSender() == owner()),
            'Error: msg.sender has not high level access'
        );
        _;
    }

    function setStateSC(bool state) external onlyOwner {
        paused = state;
        emit SetStateSC(state);
    }

    function decommissionSC(ERC20[] memory assetsToWithdraw)
        external
        onlyOwner
    {
        paused = true;
        if (address(this).balance > 0) {
            Address.sendValue(payable(msg.sender), address(this).balance);
            emit DecommissionSC(address(0), address(this).balance, msg.sender);
        }
        uint256 i;
        for (i = 0; i < assetsToWithdraw.length; i++) {
            if (assetsToWithdraw[i].balanceOf(address(this)) > 0) {
                require(
                    assetsToWithdraw[i].transfer(
                        msg.sender,
                        assetsToWithdraw[i].balanceOf(address(this))
                    ),
                    'Error on decommissionSC SettlementFeeContainer: during token transfer'
                );
                emit DecommissionSC(
                    address(assetsToWithdraw[i]),
                    assetsToWithdraw[i].balanceOf(address(this)),
                    msg.sender
                );
            }
        }
    }

    modifier checkSCUnpaused() {
        require(
            (!paused),
            'Error on checkSCUnpaused: smart contract is paused!'
        );
        _;
    }
}
