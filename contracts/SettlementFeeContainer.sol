// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SettlementFeeContainer is Ownable {

    string public description;

    using SafeERC20 for ERC20;
    bool public paused = false;
    address[] private swapPairsManagement;

    constructor (string memory _description) {
        description = _description;
    }

    receive() external payable {}
    
    function payLiquidationFee (address to, uint256 amount, address typeFeeToken) external onlyHighLevelAccess checkSCUnpaused(){
        if (typeFeeToken ==  address(0)) {
            require (to != address(0), "Error on payLiquidationFee: cannot send liquidation fee to null address");
            require (address(this).balance >= amount, "Error on payLiquidationFee: you are trying to unlock more fees than have been locked on the smart contract");
            payable(to).transfer(amount);
        } else {
            require (to != address(0), "Error on payLiquidationFee: cannot send liquidation fee to null address");
            require (ERC20(typeFeeToken).balanceOf(address(this)) >= amount, "Error on payLiquidationFee: you are trying to unlock more fees than have been locked on the smart contract");
            ERC20(typeFeeToken).safeTransfer(to, amount);
        }
    }

    function addSwapPairsManagement (address newPairAddress) public onlyOwner {
        require (!verifySwapPairsManagement(newPairAddress), "Error on addSwapPairsManagement: address to add already has swapManagement level access");
        swapPairsManagement.push(newPairAddress);
    }

    function removeSwapPairsManagement (address toDeleteAddress) public onlyOwner {
        require (verifySwapPairsManagement(toDeleteAddress), "Error on removeSwapPairsManagement: toDeleteAddress is not listed as swapManagement");
        uint256 i;
        for (i=0; i<swapPairsManagement.length; i++){
            if (swapPairsManagement[i] == toDeleteAddress){
                swapPairsManagement[i] = swapPairsManagement[swapPairsManagement.length-1];
            }
        }
        swapPairsManagement.pop();
    }

    modifier onlySwapPairsManagement () {
        require (verifySwapPairsManagement (_msgSender()), "Error: msg.sender has not swapManagement level access");
        _;        
    }

    function verifySwapPairsManagement (address toCheck) public view returns (bool isSwapManagement) {
        uint256 i;
        for (i=0; i<swapPairsManagement.length; i++){
            if (swapPairsManagement[i] == toCheck){
                return true;
            }
        }
        return false;
    }

    modifier onlyHighLevelAccess () {
        require ((verifySwapPairsManagement(_msgSender())) || (_msgSender() == owner()) , "Error: msg.sender has not high level access");
        _;        
    }

    function pauseSC () public onlyOwner {
        paused = true;
    } 

    function unpauseSC () public onlyOwner {
        paused = false;
    }

    function decommissionSC (ERC20[] memory assetsToWithdraw) public onlyOwner {
        paused = true;
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
        uint256 i;
        for (i=0; i<assetsToWithdraw.length; i++) {
            if (assetsToWithdraw[i].balanceOf(address(this)) > 0){
                require (assetsToWithdraw[i].transfer(msg.sender, assetsToWithdraw[i].balanceOf(address(this))), "Error on decommissionSC: token transfer fail");
            }
        }
    }

    modifier checkSCUnpaused() {
        require ((paused == false) , "Error on checkSCUnpaused: smart contract is paused!");
        _;
    }
}