// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../abstract/MetalSwapAbstract.sol';

contract FinancialSwapManager is Ownable {
    string public description;

    address public _governance;
    uint256 public iV;
    uint256 public settlementFeePerc;
    uint256 public PRICE_DECIMALS = 1e8;
    uint256 public constant mult6 = 1e6;

    event SetMainParameters(
        uint256 _iV,
        uint256 _settlementFeePerc,
        address __governance,
        string _description,
        uint256 _PRICE_DECIMALS
    );
    event TransferGovernance(address newGovernace);

    constructor(
        uint256 _iV,
        uint256 _settlementFeePerc,
        address __governance,
        string memory _description,
        uint256 _PRICE_DECIMALS
    ) {
        require(
            __governance != address(0),
            'Error on constructor: input cannot be zero address'
        );
        settlementFeePerc = _settlementFeePerc;
        iV = _iV;
        _governance = __governance;
        description = _description;
        PRICE_DECIMALS = _PRICE_DECIMALS;
    }

    function calcFees(uint256 period, uint256 targetSize)
        public
        view
        returns (uint256 settlementFee, uint256 periodFee)
    {
        settlementFee = getSettlementFee(targetSize);
        periodFee = getPeriodFee(targetSize, period);
    }

    function getSettlementFee(uint256 targetSize)
        public
        view
        returns (uint256 fee)
    {
        return (targetSize * settlementFeePerc) / 100 / 1e6;
    }

    function getPeriodFee(uint256 targetSize, uint256 period)
        internal
        view
        returns (uint256 fee)
    {
        return (targetSize * (sqrt(period))) / iV;
    }

    //profit and loss must be expressed accordingly (currency or asset)
    function calcPenalties(
        MetalSwapAbstract.SwapType swapType,
        uint256 targetSize,
        uint256 profit,
        uint256 loss,
        uint256 cover,
        uint256 executionTime,
        uint256 currentPrice
    ) public view returns (uint256 penalties) {
        if (executionTime <= block.timestamp) {
            return 0;
        }
        uint256 deltaTime = executionTime - block.timestamp;

        uint256 profitConvert;
        if (swapType == MetalSwapAbstract.SwapType(0)) {
            profitConvert = (profit * PRICE_DECIMALS) / currentPrice;
        } else {
            profitConvert = (profit * currentPrice) / PRICE_DECIMALS;
        }

        if (loss == 0 && profitConvert == 0) {
            return (targetSize * (sqrt(deltaTime))) / iV;
        }

        if (loss != 0) {
            uint256 lossPercent = (loss * 1e6) / cover;
            if (lossPercent > 1e6) {
                lossPercent = 1e6;
            }
            return
                (targetSize * (1e6 - lossPercent) * (sqrt(deltaTime))) /
                (iV * 1e6);
        } else if (profitConvert != 0) {
            return
                (targetSize *
                    (profitConvert + cover) *
                    1e6 *
                    (sqrt(deltaTime))) / (iV * 1e6 * cover);
        }
    }

    function calcProfitLoss(
        MetalSwapAbstract.SwapType swapType,
        uint256 currentPrice,
        uint256 initPrice,
        uint256 targetSize
    ) public view returns (uint256 profit, uint256 loss) {
        profit = 0;
        int256 priceDifference = int256(currentPrice) - int256(initPrice);

        if (swapType == MetalSwapAbstract.SwapType(0)) {
            if (priceDifference > 0) {
                loss = (targetSize * uint256(priceDifference)) / currentPrice;
                return (0, loss);
            }
            profit = (uint256(-priceDifference) * targetSize) / PRICE_DECIMALS;
            return (profit, 0);
        }

        if (swapType == MetalSwapAbstract.SwapType(1)) {
            if (priceDifference < 0) {
                loss = (targetSize * uint256(-priceDifference)) / initPrice;
                return (0, loss);
            }
            profit =
                (uint256(priceDifference) * targetSize * PRICE_DECIMALS) /
                (currentPrice * initPrice);
            return (profit, 0);
        }
    }

    function getReward(
        uint256 periodFee,
        MetalSwapAbstract.SwapType swapType,
        uint256 swapAvgAsset,
        uint256 swapAvgCurrency,
        uint256 rateReward,
        uint256 currentPrice
    ) public view returns (uint256) {
        uint256 BONUS_PERC; //bonus multiplier with 6 decimal places, 0-100% = [0-100*10^6]
        if (swapAvgAsset != 0 || swapAvgCurrency != 0) {
            if (swapType == MetalSwapAbstract.SwapType(0)) {
                BONUS_PERC =
                    (swapAvgCurrency * 100 * 2 * mult6) /
                    (swapAvgAsset + swapAvgCurrency);
                if (BONUS_PERC < 1e8) {
                    BONUS_PERC = 1e8;
                }
                return
                    (periodFee * rateReward * currentPrice * BONUS_PERC) /
                    (PRICE_DECIMALS * 1e8 * 1e6);
            }

            BONUS_PERC =
                (swapAvgAsset * 100 * 2 * mult6) /
                (swapAvgAsset + swapAvgCurrency);
            if (BONUS_PERC < 1e8) {
                BONUS_PERC = 1e8;
            }
            return (periodFee * rateReward * BONUS_PERC) / (1e8 * 1e6);
        } else {
            if (swapType == MetalSwapAbstract.SwapType(0)) {
                return
                    (periodFee * rateReward * currentPrice) /
                    (PRICE_DECIMALS * 1e6);
            }
            return (periodFee * rateReward) / 1e6;
        }
    }

    function setMainParameters(
        uint256 _iV,
        uint256 _settlementFeePerc,
        address __governance,
        string memory _description,
        uint256 _PRICE_DECIMALS
    ) external onlyGovernance {
        require(
            _settlementFeePerc < 100 * 10**6,
            'Error on setSettlementFeePerc: settlement fee percentual is not in the allowed range [0-100M] (equivalent to 0%-100% with a 6 decimal place precision)'
        );
        settlementFeePerc = _settlementFeePerc;
        iV = _iV;
        _governance = __governance;
        description = _description;
        PRICE_DECIMALS = _PRICE_DECIMALS;
        emit SetMainParameters(
            _iV,
            _settlementFeePerc,
            __governance,
            _description,
            _PRICE_DECIMALS
        );
    }

    function sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function _transferGovernance(address newGovernance) private {
        require(
            newGovernance != address(0),
            'Error on _transferGovernance: new owner cannot be zero address'
        );
        _governance = newGovernance;
    }

    function transferGovernance(address newGovernace) external onlyOwner {
        require(
            newGovernace != address(0),
            'Error on transferGovernance: new owner cannot be the null address'
        );
        _transferGovernance(newGovernace);
        emit TransferGovernance(newGovernace);
    }

    function governance() public view virtual returns (address) {
        return _governance;
    }

    modifier onlyGovernance() {
        require(
            owner() == _msgSender() || governance() == _msgSender(),
            'Error on onlyGovernance: caller is not the owner/governance'
        );
        _;
    }
}
