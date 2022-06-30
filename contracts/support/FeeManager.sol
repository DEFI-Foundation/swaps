// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../abstract/MetalSwapAbstract.sol";

contract FeeManager is Ownable {

    string public description;

    address public _governance;
    uint256 public iV;
    uint256 public settlementFeePerc;
    uint256 public PRICE_DECIMALS = 1e8;

    constructor (uint256 _iV, uint256 _settlementFeePerc, address __governance, string memory _description) {
        settlementFeePerc = _settlementFeePerc;
        iV = _iV;
        _governance = __governance;
        description = _description;
    }

    function calcFees (uint256 period, uint256 targetSize) public view returns (uint256 settlementFee, uint256 periodFee) {
        settlementFee = getSettlementFee(targetSize);
        periodFee = getPeriodFee(targetSize, period);
    }
    
    function getSettlementFee (uint256 targetSize) public view returns (uint256 fee) {
        return targetSize * settlementFeePerc / 100 / 1e6;
    }
    
    function getPeriodFee (uint256 targetSize, uint256 period) internal view returns (uint256 fee) {
        return targetSize * (sqrt(period)) / iV;
    }
    
    //beware: profit and loss must be expressed accordingly (currency or asset)
    function calcPenalties (MetalSwapAbstract.SwapType swapType, uint256 targetSize, uint256 profit, uint256 loss, uint256 cover, uint256 executionTime, uint256 currentPrice) public view returns (uint256 penalties) {
        
        if(executionTime <= block.timestamp){
            return 0;
        }
        uint256 deltaTime = executionTime - block.timestamp;

        uint256 profitConvert;
        if (swapType == MetalSwapAbstract.SwapType(0)) {
            profitConvert = profit * PRICE_DECIMALS / currentPrice;
        }
        else {
            profitConvert = profit * currentPrice / PRICE_DECIMALS ;
        }

        if(loss == 0 && profitConvert == 0 ){
            return targetSize * (sqrt(deltaTime))/iV;
        }

        if (loss != 0 ) {
            uint256 lossPercent = loss * 1e6 / cover;
            if(lossPercent > 1e6) {
                lossPercent = 1e6;
            }
            return targetSize * (1e6-lossPercent) * (sqrt(deltaTime)) / (iV * 1e6);

        } else if (profitConvert != 0 ) { 
            uint256 profitPercent = (profitConvert + cover) * 1e6 / cover;
            return targetSize * profitPercent * (sqrt(deltaTime)) / (iV * 1e6);
        }

    }

    function setiV (uint16 newiV) public onlyGovernance(){
        iV = newiV;
    }

    function setSettlementFeePerc (uint256 newSettlementFeePerc) public onlyGovernance {
        require (((newSettlementFeePerc >= 0) && (newSettlementFeePerc < 100000000)), "Error on setSettlementFeePerc: settlement fee percentual is not in the allowed range [0-100M] (equivalent to 0%-100% with a 6 decimal place precision)");
        settlementFeePerc = newSettlementFeePerc;
    }

    function decommissionSC (ERC20[] memory assetsToWithdraw) public onlyOwner {
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

    function sqrt (uint256 x) private pure returns (uint256 y) {
       uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
        y = z;
        z = (x / z + z) / 2;
        }
    }
    function governance () public view virtual returns (address) {
        return _governance;
    }

     modifier onlyGovernance () {
        require (owner() == _msgSender() || governance() == _msgSender() , "Error on onlyGovernance: caller is not the owner/governance");
        _;
    }

}