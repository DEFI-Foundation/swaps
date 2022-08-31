// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './MetalSwapPoolAbstract.sol';
import '../SettlementFeeContainer.sol';
import '../libraries/FinancialSwapManager.sol';
import '../libraries/IPriceProvider.sol';

abstract contract MetalSwapAbstract is ReentrancyGuard, Ownable {
    string public descriptionTOU;
    ERC20 public erc20Asset;
    ERC20 public erc20Currency;
    uint256 public immutable assetDecimals;
    uint256 public immutable currencyDecimals;
    ERC20 public governanceToken;
    MetalSwapPoolAbstract public poolAsset;
    MetalSwapPoolAbstract public poolCurrency;
    address public financialSwapManager;
    address public _governance;
    address public governanceTokenRewardTreasury;
    address public premiumAddress;
    SettlementFeeContainer public settlementFeeContainer;
    IPriceProvider public priceProvider;
    uint256 public rateReward;
    uint256 public swapAvgAsset;
    uint256 public swapAvgCurrency;
    uint256 public marginFactorAsset; //Note: for example, if you want to set safety margin of 50% then set this parameter to 2 (safety margin = 100/marginFactorAsset)
    uint256 public marginFactorCurrency; //Note: if a Currency is present in more than one Swap, these factors must take into account both the safety margin for the Swap as well as the liquidity availability in the pool
    uint256 public settlementFeePerc = 2 * 10**6; //Note: Must be multiplied by 10^6 (example: 0,5% = 0,5 * 100 * 10^6 = 500000)
    uint256 public PRICE_DECIMALS = 1e8;
    uint256 public constant mult6 = 1e6;
    uint256 public contractCreationTimestamp;
    uint16 public safetyMarginX100 = 5;
    bool public paused = false;
    bool public limitActive = false;
    uint256 public limitSwap;
    uint256 public minTimeSwap;
    uint256 public coverX100Min;
    uint256 public targetSizeMinAsset;
    uint256 public targetSizeMinCurrency;

    Swap[] public swaps;
    enum SwapType {
        ASSETcurrency,
        CURRENCYasset
    }
    enum State {
        Active,
        Liquidated,
        Executed,
        Closed
    }

    struct Swap {
        SwapType swapType;
        State state;
        address payable holder;
        uint16 coverX100;
        uint256 initPrice;
        uint256 targetSize;
        uint256 threshold;
        uint256 periodFee;
        uint256 initTime;
        uint256 executionTime;
        uint256 rewardAmount;
    }

    event CreatedSwap(
        uint256 indexed id,
        address indexed creator,
        SwapType swapType,
        uint256 threshold,
        uint256 executionTime,
        uint256 creationBlock
    );
    event ExecutedSwap(
        uint256 indexed id,
        address indexed creator,
        address indexed liquidator,
        uint256 profit,
        uint256 remainingCover,
        uint256 expirePrice
    );
    event ClosedSwap(
        uint256 indexed id,
        address indexed creator,
        uint256 profit,
        uint256 remainingCover,
        uint256 closingTime,
        uint256 expirePrice
    );
    event LiquidatedSwap(
        uint256 indexed id,
        address indexed creator,
        address indexed liquidator,
        uint256 liquidationTime
    );
    event AddedCoverToSwap(
        uint256 indexed id,
        address indexed creator,
        uint256 newCoverX100,
        uint256 newThreshold,
        uint256 addedCoverTime
    );
    event SetOperatingAllowance(
        address poolCurrency,
        address poolAsset,
        address settlementFeeContainer,
        address premiumAddress
    ); //poolAsset address is address(0) if the asset is ETH or other native tokens

    event FinalizeContract(
        uint256 _marginFactorAsset,
        uint256 _marginFactorCurrency,
        address _settlementFeeContainer,
        address _premiumAddress,
        address _governanceTokenRewardTreasury,
        uint256 _rateReward,
        string _descriptionTOU
    );
    event SetRewardRate(uint256 _rateReward);
    event SetMarginFactors(
        uint256 _newMarginFactorCurrency,
        uint256 _newMarginFactorAsset
    );
    event SetMainSwapParameters(
        address _governanceToken,
        address _governanceTokenRewardTreasury,
        uint256 _settlementFeePerc,
        address payable _settlementFeeContainer,
        uint256 _PRICE_DECIMALS,
        address _priceProvider
    );
    event ChangeDescriptionAndTOU(string _descriptionTOU);
    event SetStateSC(bool state);
    event TransferGovernance(address newGovernace);
    event SetSwapSafetyParameters(
        uint256 _minTimeSwap,
        bool _limitActive,
        uint256 _limitSwap,
        uint256 coverX100Min,
        uint256 targetSizeAsset,
        uint256 targetSizeMinCurrency,
        uint16 _safetyMarginX100
    );
    event SetPriceProvider(address priceProvider);

    event DecommissionSC(
        address decommissionAsset,
        uint256 decommissionBalance,
        address decommissionBeneficiary
    );

    constructor(
        ERC20 _erc20Asset,
        MetalSwapPoolAbstract _poolAsset,
        uint256 _nrOfAssetDecimals,
        ERC20 _erc20Currency,
        MetalSwapPoolAbstract _poolCurrency,
        uint256 _nrOfCurrencyDecimals,
        IPriceProvider pp,
        ERC20 _governanceToken,
        address _governanceAddr,
        address _financialSwapManager
    ) {
        require(
            address(_poolAsset) != address(0) &&
                address(_erc20Currency) != address(0) &&
                address(_poolCurrency) != address(0) &&
                address(pp) != address(0) &&
                address(_governanceToken) != address(0) &&
                _governanceAddr != address(0) &&
                _financialSwapManager != address(0),
            'Error on constructor: input cannot be zero address'
        );
        erc20Asset = _erc20Asset;
        poolAsset = _poolAsset;
        assetDecimals = _nrOfAssetDecimals;
        erc20Currency = _erc20Currency;
        poolCurrency = _poolCurrency;
        currencyDecimals = _nrOfCurrencyDecimals;
        priceProvider = pp;
        governanceToken = _governanceToken;
        _transferGovernance(_governanceAddr);
        financialSwapManager = _financialSwapManager;
        contractCreationTimestamp = block.timestamp;
    }

    function finalizeContract(
        uint256 _marginFactorAsset,
        uint256 _marginFactorCurrency,
        SettlementFeeContainer _settlementFeeContainer,
        address _premiumAddress,
        address _governanceTokenRewardTreasury,
        uint256 _rateReward,
        string memory _descriptionTOU
    ) external onlyOwner {
        require(
            address(_settlementFeeContainer) != address(0) &&
                address(_premiumAddress) != address(0) &&
                address(_governanceTokenRewardTreasury) != address(0),
            'Error on finalizeContract: input cannot be zero address'
        );
        marginFactorAsset = _marginFactorAsset;
        marginFactorCurrency = _marginFactorCurrency;
        settlementFeeContainer = _settlementFeeContainer;
        premiumAddress = payable(_premiumAddress);
        governanceTokenRewardTreasury = _governanceTokenRewardTreasury;
        rateReward = _rateReward;

        descriptionTOU = _descriptionTOU;

        setOperatingAllowance();
        emit FinalizeContract(
            _marginFactorAsset,
            _marginFactorCurrency,
            address(_settlementFeeContainer),
            _premiumAddress,
            _governanceTokenRewardTreasury,
            _rateReward,
            _descriptionTOU
        );
    }

    //approve allows the MetalSwap smart contract to tranfer funds from the ERC20 liquidity pool
    function setOperatingAllowance() public virtual onlyGovernance {}

    //createSwap allows a user to create a new Swap paying a cover
    //with Ethereum (SwapType(0)) or with stablecoin ERC20 (SwapType(1))
    function createSwap(
        uint256 period,
        uint256 targetSize,
        uint16 coverX100,
        SwapType swapType
    )
        external
        payable
        virtual
        nonReentrant
        checkSCUnpaused
        returns (uint256 swapID)
    {}

    //closeSwap allows the swap owner to close an open Swap position
    //before the executionTime paying a penalty
    function closeSwap(uint256 swapID)
        external
        virtual
        nonReentrant
        checkSCUnpaused
    {}

    //executeSwap allows the MetalSwap smart contract to execute
    //an active Swap when the executionTime arrives
    function executeSwap(uint256 swapID)
        external
        virtual
        nonReentrant
        checkSCUnpaused
    {}

    //marginCall allows the MetalSwap smart contract to close an open swap in the case the cover
    //is no longer sufficient to cover the price difference (new price - initial price) and
    //the threshold value is excedeed
    function marginCall(uint256 swapID)
        external
        virtual
        nonReentrant
        checkSCUnpaused
    {}

    //allows a user owner of an open swap to add new funds to its cover funds (expressed as new % of the
    //total value of the swap, higher than the initial % spent)
    function addCover(uint256 swapID, uint16 newCoverX100)
        external
        payable
        virtual
        nonReentrant
        checkSCUnpaused
    {}

    function getPrice() public view returns (uint256) {
        return priceProvider.getPrice();
    }

    function getTotalToSpend(
        uint256 settlementFee,
        uint256 periodFee,
        uint256 cover
    ) public pure returns (uint256) {
        return settlementFee + periodFee + cover;
    }

    //pay profit****************************************************

    //payProfit allows the MetalSwap smart contract to pay the dividends to the owner of a swap
    function payProfit(
        Swap memory swap,
        uint256 penalties,
        uint256 currentPrice,
        uint256 rewardAmount
    ) internal virtual returns (uint256 profit, uint256 remainingCoverReturn) {}

    function calcCoverToAdd(
        uint256 targetSize,
        uint256 coverX100,
        uint256 newCoverX100
    ) public pure returns (uint256 coverToAdd) {
        return ((newCoverX100 - coverX100) * targetSize) / 100;
    }

    function calcProfitLoss(
        SwapType swapType,
        uint256 currentPrice,
        uint256 initPrice,
        uint256 targetSize
    ) public view returns (uint256 profit, uint256 loss) {
        return
            FinancialSwapManager(financialSwapManager).calcProfitLoss(
                swapType,
                currentPrice,
                initPrice,
                targetSize
            );
    }

    function calcPenalties(
        SwapType swapType,
        uint256 targetSize,
        uint256 profit,
        uint256 loss,
        uint256 cover,
        uint256 executionTime,
        uint256 currentPrice
    ) public view returns (uint256 penalties) {
        return
            FinancialSwapManager(financialSwapManager).calcPenalties(
                swapType,
                targetSize,
                profit,
                loss,
                cover,
                executionTime,
                currentPrice
            );
    }

    function getSwapFeesAndReward(
        uint256 period,
        uint256 targetSize,
        SwapType swapType
    ) public view returns (uint256 fees, uint256 reward) {
        (uint256 settlementFee, uint256 periodFee) = FinancialSwapManager(
            financialSwapManager
        ).calcFees(period, targetSize);
        fees = settlementFee + periodFee;
        reward = getReward(periodFee, swapType);
    }

    function getReward(uint256 periodFee, SwapType swapType)
        public
        view
        returns (uint256 reward)
    {
        return
            FinancialSwapManager(financialSwapManager).getReward(
                periodFee,
                swapType,
                swapAvgAsset,
                swapAvgCurrency,
                rateReward,
                getPrice()
            );
    }

    function calcCoverToAdd(
        uint256 targetSize,
        uint16 oldCoverX100,
        uint16 newCoverX100
    ) external pure returns (uint256 amountToAddToOldCover) {
        return ((newCoverX100 - oldCoverX100) * targetSize) / 100;
    }

    //******************* support functions *****************************

    function calcRewardPenalties(
        uint256 rewardAmount,
        uint256 initTime,
        uint256 executionTime
    ) public view returns (uint256 rewardPenalties) {
        if (block.timestamp > executionTime) {
            return 0;
        }
        return
            (rewardAmount * (executionTime - block.timestamp)) /
            (executionTime - initTime);
    }

    function setRewardRate(uint256 _rateReward) external onlyGovernance {
        rateReward = _rateReward;
        emit SetRewardRate(_rateReward);
    }

    function lockFunds(
        SwapType _swapType,
        uint256 _cover,
        address payable _swapHolder
    ) internal virtual {}

    function unlockFunds(SwapType _swapType, uint256 _cover) internal virtual {}

    modifier onlyGovernance() {
        require(
            owner() == _msgSender() || governance() == _msgSender(),
            'Error on onlyGovernance: caller is not the owner/governance'
        );
        _;
    }

    function _transferGovernance(address newGovernance) private {
        require(
            newGovernance != address(0),
            'Error on _transferGovernance: new owner cannot be zero address'
        );
        _governance = newGovernance;
    }

    function governance() public view returns (address) {
        return _governance;
    }

    function setPriceProvider(address _priceProvider) external onlyOwner {
        require(
            _priceProvider != address(0),
            'Error on setPriceProvider: input cannot be zero address'
        );
        priceProvider = IPriceProvider(_priceProvider);
        emit SetPriceProvider(_priceProvider);
    }

    function setSwapSafetyParameters(
        uint256 _minTimeSwap,
        bool _limitActive,
        uint256 _limitSwap,
        uint256 _coverX100Min,
        uint256 _targetSizeMinAsset,
        uint256 _targetSizeMinCurrency,
        uint16 _safetyMarginX100
    ) external onlyGovernance {
        minTimeSwap = _minTimeSwap;
        limitActive = _limitActive;
        limitSwap = _limitSwap;
        coverX100Min = _coverX100Min;
        targetSizeMinAsset = _targetSizeMinAsset;
        targetSizeMinCurrency = _targetSizeMinCurrency;
        safetyMarginX100 = _safetyMarginX100;

        emit SetSwapSafetyParameters(
            _minTimeSwap,
            _limitActive,
            _limitSwap,
            _coverX100Min,
            _targetSizeMinAsset,
            _targetSizeMinCurrency,
            _safetyMarginX100
        );
    }

    function verifySwapPermission(uint256 targetSize, SwapType swapDirection)
        public
        view
        returns (bool swapPermission)
    {
        //targetSize must NOT be normalized in input

        uint256 currentPrice = getPrice();

        if (swapDirection == SwapType(0)) {
            targetSize =
                (formatAmount(targetSize, assetDecimals, 18) * currentPrice) /
                PRICE_DECIMALS;
        } else {
            targetSize = formatAmount(targetSize, currencyDecimals, 18);
        }

        if (limitActive) {
            if (swapAvgCurrency + swapAvgAsset + targetSize > limitSwap)
                return false;
        }

        uint256 assetPoolAvailability = (formatAmount(
            poolAsset.availableBalance(),
            assetDecimals,
            18
        ) * currentPrice) /
            PRICE_DECIMALS /
            marginFactorAsset;

        uint256 currencyPoolAvailability = formatAmount(
            poolCurrency.availableBalance(),
            currencyDecimals,
            18
        ) / marginFactorCurrency;

        if (swapDirection == SwapType(0)) {
            if (swapAvgAsset + targetSize >= swapAvgCurrency) {
                return
                    swapAvgAsset + targetSize - swapAvgCurrency <
                    currencyPoolAvailability;
            }
            return true;
        }

        if (swapDirection == SwapType(1)) {
            if (swapAvgAsset <= swapAvgCurrency + targetSize) {
                return
                    swapAvgCurrency + targetSize - swapAvgAsset <
                    assetPoolAvailability;
            }
            return true;
        }
    }

    function setMarginFactors(
        uint256 _newMarginFactorCurrency,
        uint256 _newMarginFactorAsset
    ) external onlyGovernance {
        marginFactorAsset = _newMarginFactorAsset;
        marginFactorCurrency = _newMarginFactorCurrency;
        emit SetMarginFactors(_newMarginFactorCurrency, _newMarginFactorAsset);
    }

    function setMainSwapParameters(
        address _governanceToken,
        address _governanceTokenRewardTreasury,
        uint256 _settlementFeePerc,
        address payable _settlementFeeContainer,
        uint256 _PRICE_DECIMALS,
        address _priceProvider
    ) external onlyOwner {
        require(
            _governanceToken != address(0) &&
                _governanceTokenRewardTreasury != address(0) &&
                _settlementFeeContainer != address(0) &&
                _priceProvider != address(0),
            'Error on setMainSwapParameters: input cannot be zero address'
        );
        governanceToken = ERC20(_governanceToken);
        governanceTokenRewardTreasury = _governanceTokenRewardTreasury;
        settlementFeePerc = _settlementFeePerc;
        settlementFeeContainer = SettlementFeeContainer(
            _settlementFeeContainer
        );
        PRICE_DECIMALS = _PRICE_DECIMALS;
        priceProvider = IPriceProvider(_priceProvider);
        emit SetMainSwapParameters(
            _governanceToken,
            _governanceTokenRewardTreasury,
            _settlementFeePerc,
            _settlementFeeContainer,
            _PRICE_DECIMALS,
            _priceProvider
        );
    }

    //getters for SC main variables

    function getSwapAvgsAndPoolAvailabilities()
        public
        view
        returns (
            uint256 avgAsset,
            uint256 avgCurrency,
            uint256 poolAssetAvailability,
            uint256 poolCurrencyAvailability
        )
    {
        return (
            swapAvgAsset,
            swapAvgCurrency,
            poolAsset.availableBalance(),
            poolCurrency.availableBalance()
        );
    }

    function formatAmount(
        uint256 _inputAmount,
        uint256 _nrOfDecimalsIn,
        uint256 _nrOfDecimalsOut
    ) public pure returns (uint256 outputAmount) {
        //ex: 300 USDT = 300 * 10^6 to convert
        if (_nrOfDecimalsIn > _nrOfDecimalsOut) {
            return _inputAmount / (10**(_nrOfDecimalsIn - _nrOfDecimalsOut)); // in output (normalize-DOWN): 300*10^18 / (10 ** (18-6)) = 300*10^18/10^12 = 300*10^6
        } else {
            return _inputAmount * (10**(_nrOfDecimalsOut - _nrOfDecimalsIn)); // in input (normalize-UP): 300*10^6 * (10 **(18-6)) = 300*10^6*10^12 = 300*10^18
        }
    }

    function changeDescriptionAndTOU(string memory _descriptionTOU)
        external
        onlyOwner
    {
        descriptionTOU = _descriptionTOU;
        emit ChangeDescriptionAndTOU(_descriptionTOU);
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
                    'Error on decommissionSC Swap: during token transfer'
                );
                emit DecommissionSC(
                    address(assetsToWithdraw[i]),
                    assetsToWithdraw[i].balanceOf(address(this)),
                    msg.sender
                );
            }
        }
    }

    function transferGovernance(address newGovernace) external onlyOwner {
        require(
            newGovernace != address(0),
            'Error on transferGovernance: new owner cannot be the null address'
        );
        _transferGovernance(newGovernace);
        emit TransferGovernance(newGovernace);
    }

    modifier checkSCUnpaused() {
        require(
            (!paused),
            'Error on checkSCUnpaused: smart contract is paused!'
        );
        _;
    }
}
