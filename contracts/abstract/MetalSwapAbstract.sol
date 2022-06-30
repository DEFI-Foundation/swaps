// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";                  //deactivated for test purposes
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "./AggregatorInterface.sol";                               //toDo: added ONLY for test purposes, to REMOVE
import "./MetalSwapPoolAbstract.sol";
import "../SettlementFeeContainer.sol";  
import "../libraries/FeeManager.sol" ;

abstract contract MetalSwapAbstract is ReentrancyGuard, Ownable {

    string public description;
    string public terms_of_use;

    ERC20 public erc20Asset; 
    ERC20 public erc20Currency;
    uint256 public assetDecimals; 
    uint256 public currencyDecimals;

    ERC20 public governanceToken;
    MetalSwapPoolAbstract public poolAsset;
    MetalSwapPoolAbstract public poolCurrency;
    address public feeManager;
    address public _governance;
    address public governanceTokenRewardTreasury;
    address public premiumAddress;
    SettlementFeeContainer public settlementFeeContainer;
    AggregatorInterface public priceProvider;

    uint256 public rateReward;

    uint256 public swapAvgAsset;       
    uint256 public swapAvgCurrency;     

    uint256 public marginFactorAsset;          //Note: for example, if you want to set safety margin of 50% then set this parameter to 2 (safety margin = 100/marginFactorAsset)
    uint256 public marginFactorCurrency;       //Note: if a Currency is present in more than one Swap, these factors must take into account both the safety margin for the Swap as well as the liquidity availability in the pool
    
    uint256 public settlementFeePerc = 2000000;      //toDo: hardcoded, to add set method in order to be able to change it. Must be multiplied by 10^6 (example: 0,5% = 0,5 * 100 * 10^6 = 500000)
    uint256 public PRICE_DECIMALS = 1e8;
    uint256 public mult6 = 1e6;
    uint256 public contractCreationTimestamp;
    
    uint16 public safetyMarginX100 = 5;
    bool public paused = false;

    uint256 public minTimeSwap;
    
    Swap[] public swaps;
    enum SwapType {ASSETcurrency, CURRENCYasset}
    enum State {Active, Liquidated, Executed, Closed}

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

    event CreatedSwap (uint256 indexed id, address indexed creator,SwapType swapType,uint256 threshold, uint256 executionTime ,uint256 creationBlock);
    event ExecutedSwap (uint256 indexed id, address indexed creator, address indexed liquidator, uint256 profit, uint256 remainingCover);
    event ClosedSwap (uint256 indexed id, address indexed creator, uint256 profit, uint256 remainingCover, uint256 closingTime);
    event LiquidatedSwap (uint256 indexed id, address indexed creator, address indexed liquidator, uint256 liquidationTime);
    event AddedCoverToSwap(uint256 indexed id, address indexed creator, uint256 newCoverX100, uint256 addedCoverTime);
    
    constructor (ERC20  _erc20Asset, MetalSwapPoolAbstract _poolAsset, uint256 _nrOfAssetDecimals, ERC20  _erc20Currency, MetalSwapPoolAbstract _poolCurrency, 
                uint256 _nrOfCurrencyDecimals, AggregatorInterface pp,  ERC20 _governanceToken, address governanceAddr, address _feeManager ) {

        erc20Asset = _erc20Asset;
        poolAsset = _poolAsset;
        assetDecimals = _nrOfAssetDecimals;
        erc20Currency = _erc20Currency;
        poolCurrency = _poolCurrency;
        currencyDecimals = _nrOfCurrencyDecimals;

        priceProvider = pp;
        governanceToken = _governanceToken;
        _transferGovernance(governanceAddr);
        feeManager = _feeManager;
        contractCreationTimestamp = block.timestamp;
    }

    function finalizeContract ( uint256 _marginFactorAsset, uint256 _marginFactorCurrency, 
                                SettlementFeeContainer _settlementFeeContainer, address _premiumAddress,
                                address _governanceTokenRewardTreasury, uint256 _rateReward, uint256 _minTimeSwap,
                                string memory _description, string memory _termsOfUse) public onlyOwner {
        
        marginFactorAsset = _marginFactorAsset;
        marginFactorCurrency = _marginFactorCurrency;
        settlementFeeContainer = _settlementFeeContainer;
        premiumAddress = payable(_premiumAddress);
        governanceTokenRewardTreasury = _governanceTokenRewardTreasury;
        rateReward = _rateReward;
        minTimeSwap =  _minTimeSwap;

        description = _description;
        terms_of_use = _termsOfUse;

        setOperatingAllowance();
    }
    
    function setSettlementFeeContainer(SettlementFeeContainer recipient) external onlyOwner {
        require(address(recipient) != address(0), "Error on setSettlementFeeContainer: settlementFeeContainer cannot be zero address");
        settlementFeeContainer = recipient;
    }
    
    //approve allows the MetalSwap smart contract to tranfer funds from the ERC20 liquidity pool
    function setOperatingAllowance() virtual public onlyGovernance{}
    
    //createSwap allows a user to create a new Swap paying a cover
    //with Ethereum (SwapType(0)) or with stablecoin ERC20 (SwapType(1))
    function createSwap (uint256 period, uint256 targetSize, uint16 coverX100, SwapType swapType) public nonReentrant virtual payable checkSCUnpaused() returns (uint256 swapID) {}

    //closeSwap allows the swap owner to close an open Swap position 
        //before the executionTime paying a penalty
    function closeSwap(uint256 swapID) public nonReentrant virtual checkSCUnpaused() {}
    
    //executeSwap allows the MetalSwap smart contract to execute
        //an active Swap when the executionTime arrives
    function executeSwap(uint256 swapID) public nonReentrant virtual checkSCUnpaused() {}
    
    //marginCall allows the MetalSwap smart contract to close an open swap in the case the cover
        //is no longer sufficient to cover the price difference (new price - initial price) and 
        //the threshold value is excedeed
    function marginCall(uint256 swapID) public nonReentrant virtual checkSCUnpaused() {}
    
    //allows a user owner of an open swap to add new funds to its cover funds (expressed as new % of the 
        //total value of the swap, higher than the initial % spent)
    function addCover(uint256 swapID, uint16 newCoverX100) public nonReentrant payable virtual checkSCUnpaused() {}

    function getPrice() public view returns (uint256) {
        return uint256(priceProvider.latestAnswer());
    }

    function getTotalToSpend(uint256 settlementFee, uint256 periodFee, uint256 cover) public pure returns (uint256) {
        return settlementFee + periodFee + cover;
    }
    
    //pay profit****************************************************
    
    //payProfit allows the MetalSwap smart contract to pay the dividends to the owner of a swap
    function payProfit(Swap memory swap, uint256 penalties, uint256 currentPrice, uint256 rewardAmount) internal virtual returns (uint256 profit, uint256 remainingCoverReturn){}

    function setTokenRewardTreasury (address _governanceTokenRewardTreasury) public onlyGovernance {
        governanceTokenRewardTreasury = _governanceTokenRewardTreasury;
    }


    function calcProfitLoss(SwapType swapType, uint256 currentPrice, uint256 initPrice, uint256 targetSize) public view  returns (uint256 profit, uint256 loss) {
        profit = 0;
        uint256 targetSizeReduced = targetSize / PRICE_DECIMALS;
        int256 priceDifference = int256(currentPrice) - int256(initPrice);

        if (swapType == SwapType(0)) {
            if (priceDifference > 0) {
                loss = targetSize * uint256(priceDifference) / currentPrice;
                return (0, loss);
            }
            profit = uint256(-priceDifference) * targetSizeReduced;
            return (profit,0);
        }

        if (swapType == SwapType(1)) {
            if (priceDifference < 0) {
                loss = targetSize * uint256(- priceDifference) / initPrice;
                return (0,loss);
            }
            uint256 targetASSET = targetSize / initPrice;
            profit = uint256(priceDifference) * targetASSET * PRICE_DECIMALS / currentPrice;
            return (profit, 0);
        }
    }

    //fees **************************************************

    function calcPenalties(SwapType swapType,uint256 targetSize, uint256 profit, uint256 loss, uint256 cover, uint256 executionTime, uint256 currentPrice) public view returns (uint256 penalities){

        return FeeManager(feeManager).calcPenalties (swapType, targetSize, profit, loss, cover, executionTime, currentPrice);

    }

    function getSwapFeesAndReward(uint256 period, uint256 targetSize, SwapType swapType) public view returns (uint256 fees, uint256 reward ){
        (uint256 settlementFee, uint256 periodFee) = FeeManager(feeManager).calcFees(period,targetSize);
        fees = settlementFee + periodFee;
        reward = getReward(periodFee, swapType);
    }

    function getReward(uint256 periodFee, SwapType swapType) public view returns (uint256){
        uint256 BONUS_PERC;                                                                                         //bonus multiplier with 6 decimal places, 0-100% = [0-100*10^6]
        if(swapAvgAsset != 0 || swapAvgCurrency != 0) {
            uint256 assetPerc = (swapAvgAsset * 100 * mult6) / (swapAvgAsset + swapAvgCurrency);                    //assetPerc is a percentual with 6 decimal places          25% (=0,25*100*10^6)
            uint256 currencyPerc = (swapAvgCurrency * 100 * mult6) / (swapAvgAsset + swapAvgCurrency);              //currencyPerc is a percentual with 6 decimal places       75% (=0,75*100*10^6)                                                                              
                                                                                                                    
            if(swapType == SwapType(0)) {
                BONUS_PERC = currencyPerc * 2;
                if(BONUS_PERC < 1e8){
                    BONUS_PERC = 1e8;
                }
                return periodFee * rateReward * getPrice() * BONUS_PERC / (PRICE_DECIMALS * 1e8 * 1e6);
            }

            BONUS_PERC = assetPerc * 2;
            if(BONUS_PERC < 1e8){
                BONUS_PERC = 1e8;
            }
            return periodFee * rateReward * BONUS_PERC / (1e8 * 1e6);
        }
        else {
            if(swapType == SwapType(0)) {
                return periodFee * rateReward * getPrice() / (PRICE_DECIMALS * 1e6);
            }
            return periodFee * rateReward / 1e6;
        }
    }

    function getSafetyMarginX100() public view returns(uint256){
        return safetyMarginX100;
    }
    
    function calcCoverToAdd (uint256 targetSize, uint16 oldCoverX100, uint16 newCoverX100)  public pure returns (uint256 amountToAddToOldCover){
        return (newCoverX100 - oldCoverX100) * targetSize / 100;
    }
    
    //******************* support functions *****************************
    
    function setSafetyMarginX100 (uint16 newSafetyMarginX100) public onlyGovernance(){
        safetyMarginX100 = newSafetyMarginX100;
    }

    function calcRewardPenalties(uint256 rewardAmount, uint256 initTime , uint256 executionTime) public view returns(uint256 rewardPenalties) {
        if (block.timestamp > executionTime) {
            return 0;
        }
        return rewardAmount * (executionTime - block.timestamp) /(executionTime - initTime);
    }

    function setRewardRate (uint256 _rateReward) public onlyGovernance() {
        rateReward = _rateReward;
    }

    function lockFunds (SwapType _swapType, uint256 _cover, address payable _swapHolder) internal virtual  {
    }
    
    function unlockFunds (SwapType _swapType, uint256 _cover) internal virtual  {
    }
    
    modifier onlyGovernance() {
        require(owner() == _msgSender() || governance() == _msgSender() , "Error on onlyGovernance: caller is not the owner/governance");
        _;
    }

    function transferGovernance(address newGovernance) public virtual onlyOwner {
        require(newGovernance != address(0), "Error on transferGovernance: new owner cannot be zero address");
        _transferGovernance(newGovernance);
    }
    
    function _transferGovernance(address newGovernance) internal virtual {
        _governance = newGovernance;
    }
     
    function governance() public view virtual returns (address) {
        return _governance;
    }

    function verifySwapPermission (uint256 targetSize, SwapType swapDirection) public view returns (bool swapPermission){        //targetSize must NOT be normalized in input

        if (swapDirection == SwapType(0)) {
            targetSize = formatAmount(targetSize, assetDecimals, 18);
        } else {
            targetSize = formatAmount(targetSize, currencyDecimals, 18);
        }
       
        uint256 assetPoolAvailability = formatAmount(poolAsset.availableBalance(), assetDecimals, 18) * getPrice() / PRICE_DECIMALS / marginFactorAsset ;      //10^18

        uint256 currencyPoolAvailability = formatAmount(poolCurrency.availableBalance(), currencyDecimals, 18) / marginFactorCurrency;      //10^18

        if (swapDirection == SwapType(0)){
            uint256 targetSizeAsset2Currency = targetSize * getPrice() / PRICE_DECIMALS;
            if (swapAvgAsset + targetSizeAsset2Currency >= swapAvgCurrency) {
                return swapAvgAsset + targetSizeAsset2Currency - swapAvgCurrency < currencyPoolAvailability;
            }
            return true;
        }

        if(swapDirection == SwapType(1)){
            if(swapAvgAsset <= swapAvgCurrency + targetSize) {
                return swapAvgCurrency + targetSize - swapAvgAsset < assetPoolAvailability;
            }
            return true;
        }

    }

    function setMinTimeSwap(uint256 _minTimeSwap)public onlyGovernance{
       minTimeSwap =_minTimeSwap;
    }

    function setMarginFactorAsset (uint256 _newMarginFactorAsset) public onlyGovernance {
        marginFactorAsset = _newMarginFactorAsset;
    }

    function setMarginFactorCurrency (uint256 _newMarginFactorCurrency) public onlyGovernance {
        marginFactorCurrency = _newMarginFactorCurrency;
    }

    function setMainSwapParameters (address _governanceToken, address _governanceTokenRewardTreasury, uint256 _rateReward, uint256 _swapAvgCurrency, uint256 _swapAvgAsset, uint256 _marginFactorAsset, 
                                                    uint256 _marginFactorCurrency, uint256 _settlementFeePerc, address addrGovernance, address payable _settlementFeeContainer ) public onlyOwner {
        governanceToken = ERC20(_governanceToken);
        governanceTokenRewardTreasury = _governanceTokenRewardTreasury;
        rateReward = _rateReward;
        swapAvgCurrency = _swapAvgCurrency; 
        swapAvgAsset = _swapAvgAsset;
        marginFactorAsset = _marginFactorAsset;
        marginFactorCurrency = _marginFactorCurrency;
        settlementFeePerc = _settlementFeePerc;
        _governance = addrGovernance;
        settlementFeeContainer = SettlementFeeContainer(_settlementFeeContainer);
    }

    function setSecondarySwapParameters ( uint256 _PRICE_DECIMALS, address _priceProvider, uint256 _contractCreationTimestamp, address payable _poolAsset, address payable _poolCurrency,
                                        uint16 _safetyMarginX100, address payable _premiumAddress, address _erc20Asset, address _erc20Currency ) public onlyOwner {
        PRICE_DECIMALS = _PRICE_DECIMALS;
        priceProvider = AggregatorInterface(_priceProvider);
        contractCreationTimestamp = _contractCreationTimestamp;
        poolAsset = MetalSwapPoolAbstract(_poolAsset);
        poolCurrency = MetalSwapPoolAbstract(_poolCurrency);
        safetyMarginX100 = _safetyMarginX100;
        premiumAddress = _premiumAddress;
        erc20Asset = ERC20(_erc20Asset); 
        erc20Currency = ERC20(_erc20Currency);
    }
    
    //getters for SC main variables
    function getMarginFactorAsset() public view returns (uint256 mFAsset) {
        return marginFactorAsset;
    }

    function getMarginFactorCurrency() public view returns (uint256 mFCurrency){
        return marginFactorCurrency;
    }

    function getSwapAvgsAndPoolAvailabilities() public view returns (uint256 avgAsset, uint256 avgCurrency, uint256 poolAssetAvailability, uint256 poolCurrencyAvailability){
        return (swapAvgAsset, swapAvgCurrency, poolAsset.availableBalance(), poolCurrency.availableBalance());
    }

    function formatAmount (uint256 _inputAmount, uint256 _nrOfDecimalsIn, uint256 _nrOfDecimalsOut) public pure returns (uint256 outputAmount) {     //ex: 300 USDT = 300 * 10^6 to convert
        if (_nrOfDecimalsIn > _nrOfDecimalsOut) {
            return _inputAmount / (10 ** (_nrOfDecimalsIn - _nrOfDecimalsOut));     // in output (normalize-DOWN): 300*10^18 / (10 ** (18-6)) = 300*10^18/10^12 = 300*10^6
        } else {
            return _inputAmount * (10 ** (_nrOfDecimalsOut - _nrOfDecimalsIn));     // in input (normalize-UP): 300*10^6 * (10 **(18-6)) = 300*10^6*10^12 = 300*10^18
        }
    }

    function changeDescriptionAndTOU (string memory _description, string memory _termsOfUse) public onlyOwner {
        description = _description;
        terms_of_use = _termsOfUse;
    }

    function pauseSC () public onlyOwner {
        paused = true;
    } 

    function unpauseSC () public onlyOwner {
        paused = false;
    }

    function decommissionSC (ERC20[] memory assetsToWithdraw) public onlyOwner {
        paused = true;
        if(address(this).balance > 0){
            payable(msg.sender).transfer(address(this).balance);
        }
        uint256 i;
        for(i=0; i<assetsToWithdraw.length; i++){
            if(assetsToWithdraw[i].balanceOf(address(this)) > 0){
                require (assetsToWithdraw[i].transfer(msg.sender, assetsToWithdraw[i].balanceOf(address(this))), "Error on decommissionSC: during token transfer");
            }
        }
    }

    modifier checkSCUnpaused() {
        require((paused == false) , "Error on checkSCUnpaused: smart contract is paused!");
        _;
    }
    
}