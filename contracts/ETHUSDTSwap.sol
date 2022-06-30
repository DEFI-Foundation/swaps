// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./abstract/MetalSwapAbstract.sol";

contract ETHUSDTSwap is MetalSwapAbstract  {

    using SafeERC20 for ERC20;     //to evaluate: safeERC20 transfers for all ERC tokens (also governance token)? To put in abstract class to implementations?

    constructor (ERC20  _erc20Asset, MetalSwapPoolAbstract _poolAsset, uint256 _nrOfAssetDecimals, ERC20  _erc20Currency, MetalSwapPoolAbstract _poolCurrency, 
                uint256 _nrOfCurrencyDecimals, AggregatorInterface pp,  ERC20 _governanceToken, address governanceAddr, address _feeManager) 
                MetalSwapAbstract(_erc20Asset, _poolAsset, _nrOfAssetDecimals, _erc20Currency, _poolCurrency, _nrOfCurrencyDecimals, pp, _governanceToken, governanceAddr, _feeManager) {
    }

    function createSwap (uint256 period, uint256 targetSize, uint16 coverX100, SwapType swapType) public nonReentrant override payable checkSCUnpaused() returns (uint256 swapID) {

        require (period>= minTimeSwap,"Error on createSwap: cannot create the requested swap because period of the swap is to short");
        
        require (verifySwapPermission(targetSize, swapType), "Error on createSwap: cannot create the requested swap because out of safety margins!");   //targetSize must NOT be normalized in input

        if (swapType == SwapType(0)) {
            targetSize = formatAmount(targetSize, assetDecimals, 18);
        } else {
            targetSize = formatAmount(targetSize, currencyDecimals, 18);
        }

        (uint256 settlementFee, uint256 periodFee) = FeeManager(feeManager).calcFees(period, targetSize);
        
        uint256 threshold;
        uint256 cover = targetSize * coverX100 / 100;
            
        uint256 totalToSpend = getTotalToSpend(settlementFee, periodFee, cover);
        uint256 currentPrice = getPrice();

        if (swapType == SwapType(0)) {          //swapType==SwapType(0) is the swapType ETH->usd
            require(msg.value == totalToSpend, "Error on createSwap: Wrong transaction ETH value");             //toDo: to change on BTCUSDTSwap
            threshold = currentPrice+currentPrice*(coverX100-safetyMarginX100)/100;
            payable(premiumAddress).transfer(periodFee);
            payable(address(settlementFeeContainer)).transfer(settlementFee);
            swapAvgAsset += targetSize * getPrice()/PRICE_DECIMALS;         //update of the avgSwap value
        } else {                              //the ELSE refers to the swapType USD->eth
            threshold = currentPrice-currentPrice * (coverX100-safetyMarginX100) / 100;
            ERC20(erc20Currency).safeTransferFrom(msg.sender, address(premiumAddress), formatAmount(periodFee, 18, currencyDecimals));
            ERC20(erc20Currency).safeTransferFrom(msg.sender, address(settlementFeeContainer), formatAmount(settlementFee, 18, currencyDecimals));
            swapAvgCurrency += targetSize;          //update of the avgSwap value
            
        }
        uint256 rewardAmount = getReward(periodFee,swapType);
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
            
        emit CreatedSwap(swapID, msg.sender, swapType, threshold, executionTime, block.number);

        return swapID;
    }

    function closeSwap (uint256 swapID) public nonReentrant override checkSCUnpaused() {
        Swap storage swap = swaps[swapID];
        
        require (swap.holder == msg.sender, "Error on closeSwap: msg.sender is not swap holder");
        require (swap.state == State.Active, "Error on closeSwap: swap position is not active");

        uint256 cover = swap.targetSize * swap.coverX100 / 100;
        uint256 currentPrice = getPrice();
        require (((swap.swapType == SwapType(0)) && swap.threshold > currentPrice) || ((swap.swapType==SwapType(1)) && swap.threshold < currentPrice) , "Error on closeSwap: swap in margin call");
        
        require (block.timestamp < swap.executionTime, "Error on closeSwap: execution time already reached");

        (uint256 profitCalc, uint256 loss) = calcProfitLoss(swap.swapType, currentPrice, swap.initPrice, swap.targetSize);

        uint256 penalties = FeeManager(feeManager).calcPenalties (swap.swapType, swap.targetSize, profitCalc, loss, cover, swap.executionTime, currentPrice);
        require (cover > penalties, "Error on closeSwap: penalities are bigger than cover");
        
        swap.state = State.Closed;

        uint256 rewardPenalties = calcRewardPenalties(swap.rewardAmount,swap.initTime,swap.executionTime);

        require (swap.rewardAmount >= rewardPenalties, "Error on closeSwap: error during assign reward");

        (uint256 profit, uint256 remainingCoverReturn) = payProfit(swap, penalties, currentPrice , swap.rewardAmount - rewardPenalties );

        uint256 settlementFee = FeeManager(feeManager).getSettlementFee(swap.targetSize);
        if (swap.swapType == SwapType(0)) {
            settlementFeeContainer.payLiquidationFee(payable(msg.sender), settlementFee, address(erc20Asset));
            emit ClosedSwap (swapID, swap.holder, formatAmount(profit, 18, currencyDecimals), remainingCoverReturn, block.timestamp);
        }
        else {
            settlementFeeContainer.payLiquidationFee(payable(msg.sender), formatAmount(settlementFee, 18, currencyDecimals), address(erc20Currency));
            emit ClosedSwap (swapID, swap.holder, profit, formatAmount(remainingCoverReturn, 18, currencyDecimals), block.timestamp);
        }       
    }

    function executeSwap (uint256 swapID) public nonReentrant override checkSCUnpaused() {
        Swap storage swap = swaps[swapID];
        require (swap.state == State.Active, "Error on executeSwap: swap position is not active");
        require (swap.executionTime <= block.timestamp, "Error on executeSwap: execution time not yet reached");
        uint256 currentPrice = getPrice();
        require (((swap.swapType==SwapType(0)) && swap.threshold > currentPrice) || ((swap.swapType==SwapType(1)) && swap.threshold < currentPrice) , "Error on executeSwap: swap in margin call");
        
        swap.state = State.Executed;
        (uint256 profit, uint256 remainingCoverReturn) = payProfit(swap, 0, currentPrice,swap.rewardAmount);
        
        uint256 settlementFee = FeeManager(feeManager).getSettlementFee(swap.targetSize);
        if (swap.swapType==SwapType(0)) {
            settlementFeeContainer.payLiquidationFee(payable(msg.sender), settlementFee, address(erc20Asset));
            emit ExecutedSwap (swapID, swap.holder, msg.sender, formatAmount(profit, 18, currencyDecimals), remainingCoverReturn);
        }
        else {
            settlementFeeContainer.payLiquidationFee(payable(msg.sender), formatAmount(settlementFee, 18, currencyDecimals), address(erc20Currency));
            emit ExecutedSwap (swapID, swap.holder, msg.sender, profit, formatAmount(remainingCoverReturn, 18, currencyDecimals));
        }
    }

    function marginCall (uint256 swapID) public nonReentrant override checkSCUnpaused() {
        Swap storage swap = swaps[swapID];
        require (swap.state == State.Active, "Error on marginCall: swap position is not active");
        uint256 currentPrice = getPrice();
        require (((swap.swapType == SwapType(0)) && swap.threshold < currentPrice) || ((swap.swapType == SwapType(1)) && swap.threshold > currentPrice) , "Error on marginCall: the swap is not in margin call conditions!"); //swapType==SwapType(0) is the swapType ETH->usd
        
        uint256 cover = swap.targetSize * swap.coverX100 / 100;
        swap.state = State.Liquidated;
        unlockFunds(swap.swapType, cover);

        uint256 rewardPenalties = calcRewardPenalties(swap.rewardAmount,swap.initTime, swap.executionTime);

        require (swap.rewardAmount >= rewardPenalties, "Error on marginCall: error during assign reward");

        uint256 rewardToSend =  swap.rewardAmount - rewardPenalties;

        if (rewardToSend > 0){
            if (governanceToken.balanceOf(governanceTokenRewardTreasury) >= rewardToSend) {
            require (governanceToken.transferFrom(governanceTokenRewardTreasury, swap.holder, rewardToSend), "Error on marginCall: failure during XMT reward token transfer");
            }
        }

        uint256 settlementFee = FeeManager(feeManager).getSettlementFee(swap.targetSize);
        if (swap.swapType == SwapType(0)) {
            swapAvgAsset -= swap.targetSize * swap.initPrice / PRICE_DECIMALS;
            settlementFeeContainer.payLiquidationFee(payable(msg.sender), settlementFee , address(erc20Asset));
        }
        else {
            swapAvgCurrency -= swap.targetSize;
            settlementFeeContainer.payLiquidationFee(payable(msg.sender), formatAmount(settlementFee, 18, currencyDecimals), address(erc20Currency));
        }
        
        emit LiquidatedSwap (swapID, swap.holder, msg.sender, block.timestamp);
    }

    function addCover (uint256 swapID, uint16 newCoverX100) public nonReentrant payable override checkSCUnpaused() {

        Swap storage swap = swaps[swapID];
        require (swap.holder == msg.sender, "Error on addCover: msg.sender is not swap holder");
        require (newCoverX100 > swap.coverX100, "Error on addCover: new cover % too low!");
        require (swap.state == State.Active, "Error on addCover: swap position is not active");
        uint256 currentPrice = getPrice();
        require (((swap.swapType == SwapType(0)) && swap.threshold > currentPrice) || ((swap.swapType == SwapType(1)) && swap.threshold < currentPrice) , "Error on addCover: swap in margin call");     //swapType==SwapType(0) is the swapType ETH->usd
        uint256 coverToAdd = calcCoverToAdd(swap.targetSize, swap.coverX100, newCoverX100);
        
        if ((swap.swapType == SwapType(0))) {       //swapType==SwapType(0) is the swapType ETH->usd
            require (msg.value == coverToAdd, "Error on addCover: msg value not matching new cover");
            payable(poolAsset).transfer(coverToAdd);
            poolAsset.lock(coverToAdd);
            swap.threshold = swap.initPrice+swap.initPrice * (newCoverX100 - safetyMarginX100) / 100;   //calc and set the new threshold of the swap
        }
        else {                                   //swapType==SwapType(1) is the swapType USD->eth
            erc20Currency.safeTransferFrom(swap.holder, address(poolCurrency), formatAmount(coverToAdd, 18, currencyDecimals));
            poolCurrency.lock(formatAmount(coverToAdd, 18, currencyDecimals));
            swap.threshold = swap.initPrice - swap.initPrice * (newCoverX100 - safetyMarginX100) / 100;   //calc and set the new threshold of the swap
        }
        
        swap.coverX100 = newCoverX100;

        emit AddedCoverToSwap (swapID, msg.sender, swap.coverX100, block.timestamp);
    }

    function payProfit (Swap memory swap, uint256 penalties, uint256 currentPrice, uint256 rewardAmount) internal override returns (uint256 profit, uint256 remainingCoverReturn) {
        
        //governance token reward assignment based on the period fees
        
        if (rewardAmount > 0){
            if (governanceToken.balanceOf(governanceTokenRewardTreasury) >= rewardAmount) {
            require (governanceToken.transferFrom(governanceTokenRewardTreasury, swap.holder, rewardAmount), "Error on payProfit: failure during XMT reward token transfer");
            }
        }
        
        //profit calculations
        profit = 0;
        int256 priceDifference = int256(currentPrice) - int256(swap.initPrice);
        uint256 targetSizeReduced = swap.targetSize / PRICE_DECIMALS;
        uint256 cover = swap.targetSize * swap.coverX100 / 100;
        
        /*     eth         */
        if (swap.swapType == SwapType(0)) {             //swapType==SwapType(0) is the swapType ETH->usd
            swapAvgAsset -= swap.targetSize * swap.initPrice/PRICE_DECIMALS;
            if (priceDifference >= 0) {
                uint256 remainingCover = cover - (swap.targetSize * uint256(priceDifference) / currentPrice);     // 10^18 - (10^18 * 10^6 / 10^6) = 10^18
                int256 remainingCoverPenalities = int256(remainingCover) - int256(penalties);                   // 10^18 - ?
                if (remainingCoverPenalities > 0){
                    poolAsset.send(swap.holder, uint(remainingCoverPenalities));
                    unlockFunds(swap.swapType, cover);
                    return (profit, uint(remainingCoverPenalities));
                } else {
                    unlockFunds(swap.swapType, cover);
                    return (profit, 0);
                }
            }
            else {                               
                profit = uint256(- priceDifference) * targetSizeReduced;       // 10^6 * 10^12 = 10^18
                poolCurrency.sendProfit(swap.holder, formatAmount(profit, 18, currencyDecimals));
                poolAsset.send(swap.holder, cover - penalties);
                unlockFunds(swap.swapType, cover);
                return (profit, uint(cover - penalties));
            }
        }
        
        /*     usd         */
        if (swap.swapType == SwapType(1)) {             //swapType==SwapType(1) is the swapType USD->eth
            swapAvgCurrency -= swap.targetSize;
            if (priceDifference <= 0) {
                uint256 remainingCover = cover - (swap.targetSize * uint256(- priceDifference) / swap.initPrice);       // 10^18 - (10^18 * (10^8 - 10^8)) / 10^8 = 10^18
                int256 remainingCoverPenalities = int256(remainingCover) - int256(penalties);                          // 10^18 - ?
                if (remainingCoverPenalities > 0) {
                    poolCurrency.send(swap.holder, formatAmount(uint256(remainingCoverPenalities), 18, currencyDecimals));
                    unlockFunds(swap.swapType, cover);
                    return (profit, uint(remainingCoverPenalities));
                } else {
                    unlockFunds(swap.swapType, cover);
                    return (profit, 0);
                }
            }
            else {
                uint256 targetETH = swap.targetSize / swap.initPrice;                               //10^18 / 10^8 = 10^10
                profit = uint256(priceDifference) * targetETH * PRICE_DECIMALS / currentPrice;      //10^8 * 10^10 * 10^8 / 10^8 = 10^18
                poolAsset.sendProfit(swap.holder, profit);
                poolCurrency.send(swap.holder, formatAmount(cover - penalties, 18, currencyDecimals));
                unlockFunds(swap.swapType, cover);
                return (profit, uint(cover - penalties));
            }
        }
    }


    function lockFunds (SwapType _swapType, uint256 _cover, address payable _swapHolder) internal override  {
        if (_swapType==SwapType(0)) {
            payable(poolAsset).transfer(_cover);
            poolAsset.lock(_cover);
            
        } else {
            ERC20(erc20Currency).safeTransferFrom(_swapHolder, address(poolCurrency), formatAmount(_cover, 18, currencyDecimals));
            poolCurrency.lock(formatAmount(_cover, 18, currencyDecimals));
        }
    }
    
    function unlockFunds (SwapType _swapType, uint256 _cover) internal override  {
        if(_swapType==SwapType(0)) {
            poolAsset.unlock(_cover);
        } else {
            poolCurrency.unlock(formatAmount(_cover, 18, currencyDecimals));
        }
    }

    function setOperatingAllowance () override public onlyGovernance {
        erc20Currency.safeApprove(address(poolCurrency), type(uint256).max);
        erc20Currency.safeApprove(address(settlementFeeContainer), type(uint256).max);
        erc20Currency.safeApprove(address(premiumAddress), type(uint256).max);
    }

    function transferGovernance (address newGovernace) public override onlyOwner {
        require(newGovernace != address(0), "Error on transferGovernance: new owner cannot be the null address");
        _transferGovernance(newGovernace);
    }
    
    function governance () public view override returns (address) {
        return super.governance();
    }

}