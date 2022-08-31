// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './abstract/MetalSwapAbstract.sol';

contract ETHUSDTSwap is MetalSwapAbstract {
    using SafeERC20 for ERC20;

    constructor(
        ERC20 _erc20Asset,
        MetalSwapPoolAbstract _poolAsset,
        uint256 _nrOfAssetDecimals,
        ERC20 _erc20Currency,
        MetalSwapPoolAbstract _poolCurrency,
        uint256 _nrOfCurrencyDecimals,
        IPriceProvider pp,
        ERC20 _governanceToken,
        address governanceAddr,
        address _financialSwapManager
    )
        MetalSwapAbstract(
            _erc20Asset,
            _poolAsset,
            _nrOfAssetDecimals,
            _erc20Currency,
            _poolCurrency,
            _nrOfCurrencyDecimals,
            pp,
            _governanceToken,
            governanceAddr,
            _financialSwapManager
        )
    {}

    function createSwap(
        uint256 period,
        uint256 targetSize,
        uint16 coverX100,
        SwapType swapType
    )
        external
        payable
        override
        nonReentrant
        checkSCUnpaused
        returns (uint256 swapID)
    {
        require(
            coverX100 >= coverX100Min &&
                ((swapType == SwapType(0) &&
                    targetSize >= targetSizeMinAsset) ||
                    (swapType == SwapType(1) &&
                        targetSize >= targetSizeMinCurrency)) &&
                period >= minTimeSwap,
            'Error on createSwap: cannot create the requested swap because period, cover% or targetSize are out of range'
        );

        require(
            verifySwapPermission(targetSize, swapType),
            'Error on createSwap: cannot create the requested swap because out of safety margins!'
        ); //targetSize must NOT be normalized in input

        if (swapType == SwapType(0)) {
            targetSize = formatAmount(targetSize, assetDecimals, 18);
        } else {
            targetSize = formatAmount(targetSize, currencyDecimals, 18);
        }

        (uint256 settlementFee, uint256 periodFee) = FinancialSwapManager(
            financialSwapManager
        ).calcFees(period, targetSize);

        uint256 threshold;
        uint256 cover = (targetSize * coverX100) / 100;

        uint256 totalToSpend = getTotalToSpend(settlementFee, periodFee, cover);
        uint256 currentPrice = getPrice();

        if (swapType == SwapType(0)) {
            //swapType==SwapType(0) is the swapType ETH->usd
            require(
                msg.value == totalToSpend,
                'Error on createSwap: Wrong transaction ETH value'
            );
            threshold =
                currentPrice +
                (currentPrice * (coverX100 - safetyMarginX100)) /
                100;
            Address.sendValue(payable(premiumAddress), periodFee);
            Address.sendValue(payable(settlementFeeContainer), settlementFee);
            swapAvgAsset += (targetSize * getPrice()) / PRICE_DECIMALS; //update of the avgSwap value
        } else {
            //the ELSE refers to the swapType USD->eth
            threshold =
                currentPrice -
                (currentPrice * (coverX100 - safetyMarginX100)) /
                100;
            ERC20(erc20Currency).safeTransferFrom(
                msg.sender,
                address(premiumAddress),
                formatAmount(periodFee, 18, currencyDecimals)
            );
            ERC20(erc20Currency).safeTransferFrom(
                msg.sender,
                address(settlementFeeContainer),
                formatAmount(settlementFee, 18, currencyDecimals)
            );
            swapAvgCurrency += targetSize; //update of the avgSwap value
        }
        uint256 rewardAmount = getReward(periodFee, swapType);
        uint256 executionTime = block.timestamp + period;
        swapID = swaps.length;
        swaps.push(
            Swap(
                swapType,
                State.Active,
                payable(msg.sender),
                coverX100,
                currentPrice,
                targetSize,
                threshold,
                periodFee,
                block.timestamp,
                executionTime,
                rewardAmount
            )
        );

        lockFunds(swapType, cover, payable(msg.sender));

        emit CreatedSwap(
            swapID,
            msg.sender,
            swapType,
            threshold,
            executionTime,
            block.number
        );

        return swapID;
    }

    function closeSwap(uint256 swapID)
        external
        override
        nonReentrant
        checkSCUnpaused
    {
        Swap storage swap = swaps[swapID];

        require(
            swap.holder == msg.sender,
            'Error on closeSwap: msg.sender is not swap holder'
        );
        require(
            swap.state == State.Active,
            'Error on closeSwap: swap position is not active'
        );

        uint256 cover = (swap.targetSize * swap.coverX100) / 100;
        uint256 currentPrice = getPrice();
        require(
            ((swap.swapType == SwapType(0)) && swap.threshold > currentPrice) ||
                ((swap.swapType == SwapType(1)) &&
                    swap.threshold < currentPrice),
            'Error on closeSwap: swap in margin call'
        );

        require(
            block.timestamp < swap.executionTime,
            'Error on closeSwap: execution time already reached'
        );

        (uint256 profitCalc, uint256 loss) = calcProfitLoss(
            swap.swapType,
            currentPrice,
            swap.initPrice,
            swap.targetSize
        );

        uint256 penalties = FinancialSwapManager(financialSwapManager)
            .calcPenalties(
                swap.swapType,
                swap.targetSize,
                profitCalc,
                loss,
                cover,
                swap.executionTime,
                currentPrice
            );
        require(
            cover > penalties,
            'Error on closeSwap: penalties are bigger than cover'
        );

        swap.state = State.Closed;

        uint256 rewardPenalties = calcRewardPenalties(
            swap.rewardAmount,
            swap.initTime,
            swap.executionTime
        );

        require(
            swap.rewardAmount >= rewardPenalties,
            'Error on closeSwap: error during assign reward'
        );

        (uint256 profit, uint256 remainingCoverReturn) = payProfit(
            swap,
            penalties,
            currentPrice,
            swap.rewardAmount - rewardPenalties
        );

        uint256 settlementFee = FinancialSwapManager(financialSwapManager)
            .getSettlementFee(swap.targetSize);
        if (swap.swapType == SwapType(0)) {
            settlementFeeContainer.payLiquidationFee(
                payable(msg.sender),
                settlementFee,
                address(erc20Asset)
            );
            emit ClosedSwap(
                swapID,
                swap.holder,
                formatAmount(profit, 18, currencyDecimals),
                remainingCoverReturn,
                block.timestamp,
                currentPrice
            );
        } else {
            settlementFeeContainer.payLiquidationFee(
                payable(msg.sender),
                formatAmount(settlementFee, 18, currencyDecimals),
                address(erc20Currency)
            );
            emit ClosedSwap(
                swapID,
                swap.holder,
                profit,
                formatAmount(remainingCoverReturn, 18, currencyDecimals),
                block.timestamp,
                currentPrice
            );
        }
    }

    function executeSwap(uint256 swapID)
        external
        override
        nonReentrant
        checkSCUnpaused
    {
        Swap storage swap = swaps[swapID];
        require(
            swap.state == State.Active,
            'Error on executeSwap: swap position is not active'
        );
        require(
            swap.executionTime <= block.timestamp,
            'Error on executeSwap: execution time not yet reached'
        );
        uint256 currentPrice = getPrice();
        require(
            ((swap.swapType == SwapType(0)) && swap.threshold > currentPrice) ||
                ((swap.swapType == SwapType(1)) &&
                    swap.threshold < currentPrice),
            'Error on executeSwap: swap in margin call'
        );

        swap.state = State.Executed;
        (uint256 profit, uint256 remainingCoverReturn) = payProfit(
            swap,
            0,
            currentPrice,
            swap.rewardAmount
        );

        uint256 settlementFee = FinancialSwapManager(financialSwapManager)
            .getSettlementFee(swap.targetSize);
        if (swap.swapType == SwapType(0)) {
            settlementFeeContainer.payLiquidationFee(
                payable(msg.sender),
                settlementFee,
                address(erc20Asset)
            );
            emit ExecutedSwap(
                swapID,
                swap.holder,
                msg.sender,
                formatAmount(profit, 18, currencyDecimals),
                remainingCoverReturn,
                currentPrice
            );
        } else {
            settlementFeeContainer.payLiquidationFee(
                payable(msg.sender),
                formatAmount(settlementFee, 18, currencyDecimals),
                address(erc20Currency)
            );
            emit ExecutedSwap(
                swapID,
                swap.holder,
                msg.sender,
                profit,
                formatAmount(remainingCoverReturn, 18, currencyDecimals),
                currentPrice
            );
        }
    }

    function marginCall(uint256 swapID)
        external
        override
        nonReentrant
        checkSCUnpaused
    {
        Swap storage swap = swaps[swapID];
        require(
            swap.state == State.Active,
            'Error on marginCall: swap position is not active'
        );
        uint256 currentPrice = getPrice();
        require(
            ((swap.swapType == SwapType(0)) && swap.threshold < currentPrice) ||
                ((swap.swapType == SwapType(1)) &&
                    swap.threshold > currentPrice),
            'Error on marginCall: the swap is not in margin call conditions!'
        ); //swapType==SwapType(0) is the swapType ETH->usd

        uint256 cover = (swap.targetSize * swap.coverX100) / 100;
        swap.state = State.Liquidated;
        unlockFunds(swap.swapType, cover);

        uint256 rewardPenalties = calcRewardPenalties(
            swap.rewardAmount,
            swap.initTime,
            swap.executionTime
        );

        require(
            swap.rewardAmount >= rewardPenalties,
            'Error on marginCall: error during assign reward'
        );

        uint256 rewardToSend = swap.rewardAmount - rewardPenalties;

        if (rewardToSend > 0) {
            if (
                governanceToken.balanceOf(governanceTokenRewardTreasury) >=
                rewardToSend
            ) {
                require(
                    governanceToken.transferFrom(
                        governanceTokenRewardTreasury,
                        swap.holder,
                        rewardToSend
                    ),
                    'Error on marginCall: failure during XMT reward token transfer'
                );
            }
        }

        uint256 settlementFee = FinancialSwapManager(financialSwapManager)
            .getSettlementFee(swap.targetSize);
        if (swap.swapType == SwapType(0)) {
            swapAvgAsset -= (swap.targetSize * swap.initPrice) / PRICE_DECIMALS;
            settlementFeeContainer.payLiquidationFee(
                payable(msg.sender),
                settlementFee,
                address(erc20Asset)
            );
        } else {
            swapAvgCurrency -= swap.targetSize;
            settlementFeeContainer.payLiquidationFee(
                payable(msg.sender),
                formatAmount(settlementFee, 18, currencyDecimals),
                address(erc20Currency)
            );
        }

        emit LiquidatedSwap(swapID, swap.holder, msg.sender, block.timestamp);
    }

    function addCover(uint256 swapID, uint16 newCoverX100)
        external
        payable
        override
        nonReentrant
        checkSCUnpaused
    {
        Swap storage swap = swaps[swapID];
        require(
            swap.holder == msg.sender,
            'Error on addCover: msg.sender is not swap holder'
        );
        require(
            newCoverX100 > swap.coverX100,
            'Error on addCover: new cover % too low!'
        );
        require(
            swap.state == State.Active,
            'Error on addCover: swap position is not active'
        );
        uint256 currentPrice = getPrice();
        require(
            ((swap.swapType == SwapType(0)) && swap.threshold > currentPrice) ||
                ((swap.swapType == SwapType(1)) &&
                    swap.threshold < currentPrice),
            'Error on addCover: swap in margin call'
        ); //swapType==SwapType(0) is the swapType ETH->usd
        uint256 coverToAdd = calcCoverToAdd(
            swap.targetSize,
            swap.coverX100,
            newCoverX100
        );

        if ((swap.swapType == SwapType(0))) {
            //swapType==SwapType(0) is the swapType ETH->usd
            require(
                msg.value == coverToAdd,
                'Error on addCover: msg value not matching new cover'
            );
            Address.sendValue(payable(poolAsset), coverToAdd);
            poolAsset.lock(coverToAdd);
            swap.threshold =
                swap.initPrice +
                (swap.initPrice * (newCoverX100 - safetyMarginX100)) /
                100; //calc and set the new threshold of the swap
        } else {
            //swapType==SwapType(1) is the swapType USD->eth
            erc20Currency.safeTransferFrom(
                swap.holder,
                address(poolCurrency),
                formatAmount(coverToAdd, 18, currencyDecimals)
            );
            poolCurrency.lock(formatAmount(coverToAdd, 18, currencyDecimals));
            swap.threshold =
                swap.initPrice -
                (swap.initPrice * (newCoverX100 - safetyMarginX100)) /
                100; //calc and set the new threshold of the swap
        }

        swap.coverX100 = newCoverX100;

        emit AddedCoverToSwap(
            swapID,
            msg.sender,
            swap.coverX100,
            swap.threshold,
            block.timestamp
        );
    }

    function payProfit(
        Swap memory swap,
        uint256 penalties,
        uint256 currentPrice,
        uint256 rewardAmount
    ) internal override returns (uint256 profit, uint256 remainingCoverReturn) {
        //governance token reward assignment based on the period fees

        if (rewardAmount > 0) {
            if (
                governanceToken.balanceOf(governanceTokenRewardTreasury) >=
                rewardAmount
            ) {
                require(
                    governanceToken.transferFrom(
                        governanceTokenRewardTreasury,
                        swap.holder,
                        rewardAmount
                    ),
                    'Error on payProfit: failure during XMT reward token transfer'
                );
            }
        }

        //profit calculations
        profit = 0;
        int256 priceDifference = int256(currentPrice) - int256(swap.initPrice);
        uint256 cover = (swap.targetSize * swap.coverX100) / 100;

        /*     eth         */
        if (swap.swapType == SwapType(0)) {
            //swapType==SwapType(0) is the swapType ETH->usd
            swapAvgAsset -= (swap.targetSize * swap.initPrice) / PRICE_DECIMALS;
            if (priceDifference >= 0) {
                uint256 remainingCover = cover -
                    ((swap.targetSize * uint256(priceDifference)) /
                        currentPrice);
                int256 remainingCoverPenalties = int256(remainingCover) -
                    int256(penalties);
                if (remainingCoverPenalties > 0) {
                    poolAsset.send(
                        swap.holder,
                        uint256(remainingCoverPenalties)
                    );
                    unlockFunds(swap.swapType, cover);
                    return (profit, uint256(remainingCoverPenalties));
                } else {
                    unlockFunds(swap.swapType, cover);
                    return (profit, 0);
                }
            } else {
                profit =
                    (uint256(-priceDifference) * swap.targetSize) /
                    PRICE_DECIMALS;
                poolCurrency.sendProfit(
                    swap.holder,
                    formatAmount(profit, 18, currencyDecimals)
                );
                poolAsset.send(swap.holder, cover - penalties);
                unlockFunds(swap.swapType, cover);
                return (profit, uint256(cover - penalties));
            }
        }

        /*     usd         */
        if (swap.swapType == SwapType(1)) {
            //swapType==SwapType(1) is the swapType USD->eth
            swapAvgCurrency -= swap.targetSize;
            if (priceDifference <= 0) {
                uint256 remainingCover = cover -
                    ((swap.targetSize * uint256(-priceDifference)) /
                        swap.initPrice);
                int256 remainingCoverPenalties = int256(remainingCover) -
                    int256(penalties);
                if (remainingCoverPenalties > 0) {
                    poolCurrency.send(
                        swap.holder,
                        formatAmount(
                            uint256(remainingCoverPenalties),
                            18,
                            currencyDecimals
                        )
                    );
                    unlockFunds(swap.swapType, cover);
                    return (profit, uint256(remainingCoverPenalties));
                } else {
                    unlockFunds(swap.swapType, cover);
                    return (profit, 0);
                }
            } else {
                profit =
                    (uint256(priceDifference) *
                        swap.targetSize *
                        PRICE_DECIMALS) /
                    (currentPrice * swap.initPrice);
                poolAsset.sendProfit(swap.holder, profit);
                poolCurrency.send(
                    swap.holder,
                    formatAmount(cover - penalties, 18, currencyDecimals)
                );
                unlockFunds(swap.swapType, cover);
                return (profit, uint256(cover - penalties));
            }
        }
    }

    function lockFunds(
        SwapType _swapType,
        uint256 _cover,
        address payable _swapHolder
    ) internal override {
        if (_swapType == SwapType(0)) {
            Address.sendValue(payable(poolAsset), _cover);
            poolAsset.lock(_cover);
        } else {
            ERC20(erc20Currency).safeTransferFrom(
                _swapHolder,
                address(poolCurrency),
                formatAmount(_cover, 18, currencyDecimals)
            );
            poolCurrency.lock(formatAmount(_cover, 18, currencyDecimals));
        }
    }

    function unlockFunds(SwapType _swapType, uint256 _cover) internal override {
        if (_swapType == SwapType(0)) {
            poolAsset.unlock(_cover);
        } else {
            poolCurrency.unlock(formatAmount(_cover, 18, currencyDecimals));
        }
    }

    function setOperatingAllowance() public override onlyGovernance {
        erc20Currency.safeApprove(address(poolCurrency), type(uint256).max);
        erc20Currency.safeApprove(
            address(settlementFeeContainer),
            type(uint256).max
        );
        erc20Currency.safeApprove(address(premiumAddress), type(uint256).max);
        emit SetOperatingAllowance(
            address(poolCurrency),
            address(0),
            address(settlementFeeContainer),
            premiumAddress
        );
    }
}
