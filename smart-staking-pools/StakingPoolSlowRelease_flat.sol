
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: MetalSwap/StakingPools/StakingPoolV2Base.sol

pragma solidity ^0.8.7;





abstract contract StakingPoolV2base is ReentrancyGuard, Ownable {

    /* ========== STATE VARIABLES ========== */
  
    IERC20 public stakingToken;
    uint256 public startStaking;
    uint256 public endStaking;
    uint256 public poolWeightedAverage;
    
    uint256 public rewardTokensAmount; 
    uint256 public stakedTokensTotal; 
    bool public paused;
    bool private finalized;
    address public _governance;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }
    
    mapping(address => Stake[]) public userOperations; 
    mapping(address => uint256) public tokensStakedPerUser;
    mapping(address => uint256) public userWeightedAverage;
    
    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Exit(address indexed user, uint256 stakedTokens, uint256 reward);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20 _stakingToken
    ) {
        stakingToken = _stakingToken;
        _transferGovernance(_msgSender());
        paused = true;
        finalized = false;
    }

    /* ========== FUNCTIONS ========== */
       
    function finalizePoolCreation (uint256 _startStaking, uint256 periodInSec, uint256 amountOfRewardsTokensToSend,uint16 _slotNumber, uint256 _forSlotAmount) public virtual onlyGovernance nonReentrant {
        require(finalized == false, "Error: Staking Pool must be paused in order to finalize!");
        require (amountOfRewardsTokensToSend > 0, "Error: The creator must send some reward tokens to the pool in order to create it");
        require (stakingToken.transferFrom(msg.sender, address(this), amountOfRewardsTokensToSend), "Error: Reward tokens trasnfer error, cannot create pool");
        
        startStaking = _startStaking;
        
        endStaking = _startStaking + periodInSec;
        
        rewardTokensAmount = amountOfRewardsTokensToSend;

        paused = false;
        finalized = true;
        
        emit RewardAdded(amountOfRewardsTokensToSend);
    }

    function stake(uint256 amount, uint16 slotNumberForUser) public virtual nonReentrant checkPoolOpen checkStakingUnpaused{
        require(amount > 0, "Error: Cannot stake 0");
        
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Error during token transfer");
        
        tokensStakedPerUser[msg.sender] += amount;
        
        uint256 weightedAverage = calcWeightedAverage(amount);
        userWeightedAverage[msg.sender] += weightedAverage;
        
        poolWeightedAverage += weightedAverage;
        stakedTokensTotal += amount;

        userOperations[msg.sender].push(Stake(amount, block.timestamp));
        
        emit Staked(msg.sender, amount);
    }

    function exit() public virtual nonReentrant checkStakingFinished checkStakingUnpaused{
        
        uint256 stakedTokens = tokensStakedPerUser[msg.sender];
        uint256 reward = calcReward(msg.sender);
        require(stakedTokens > 0, "Error: Cannot get reward = 0");
        require(reward > 0, "Error: Cannot get reward = 0");
        tokensStakedPerUser[msg.sender] = 0;
        userWeightedAverage[msg.sender] = 0;
        require(stakingToken.transfer(msg.sender, (stakedTokens+reward)), "Error during the withdrawal of user reward");
        emit Exit(msg.sender, stakedTokens, reward);
    }

    function addRewardTokensAmount(uint256 amountToAdd) external onlyGovernance nonReentrant {
        require(stakingToken.transferFrom(msg.sender, address(this), amountToAdd), "Error during the token reward increase transaction!");
        rewardTokensAmount += amountToAdd;
        emit RewardAdded(amountToAdd);
    }
    
    function setTime(uint256 initTimestamp, uint256 endTimestamp) public onlyGovernance {
        if(endTimestamp > initTimestamp){
            startStaking = initTimestamp;
            endStaking = endTimestamp;
        }
    }
    
    function closePool() public onlyGovernance nonReentrant{     
        paused = true;                   
        require (stakingToken.transfer(msg.sender, stakingToken.balanceOf(address(this))), "Error during token transfer");
    }
    
    function pauseStaking () public onlyGovernance {
        paused = true;
    }
    
    function unpauseStaking () public onlyGovernance {
        paused = false;
    }
    
    
    /* ========== VIEWS ========== */

    function calcWeightedAverage(uint256 amount) public view returns (uint256 weightedAverage) {
        if(endStaking > startStaking){
            return amount * (endStaking - block.timestamp ) / (endStaking - startStaking );
        }
        return 0;
    }
    
    function calcReward(address user) public virtual view returns (uint256 reward) {
        if(poolWeightedAverage>0){
            return userWeightedAverage[user] * rewardTokensAmount / poolWeightedAverage;
        }
        return 0;
    }
    
    function canIStakeNow() public view returns (bool poolReady) {                  
        if((paused == false) && (block.timestamp >= startStaking) && (block.timestamp <= endStaking)){
            return true;
        }
        return false;
    }
    
    function canIExitPoolNow() public view returns (bool poolReady) {                  
        if(block.timestamp >= endStaking){
            return true;
        }
        return false;
    }


    function getPoolUserData(address user) public view returns (uint256 userStakedTokens ,uint256 userReward ){
        return (tokensStakedPerUser[user],calcReward(user));
    }

    function getStakingPeriod() public view returns (uint256 , uint256){
        return (startStaking, endStaking);
    }

    function getPoolWeightedAverage() public view returns (uint256){
        return poolWeightedAverage;
    }
    
    function getRewardTokensAmount() public view returns (uint256){
        return rewardTokensAmount;
    }
    
    function getStakedTokensTotal() public view returns (uint256){
        return stakedTokensTotal;
    }
    
    function getTokensStakedPerUser(address user) public view returns (uint256){
        return tokensStakedPerUser[user];
    }
    
    function getUserWeightedAverage(address user) public view returns (uint256){
        return userWeightedAverage[user];
    }
    
    function transferGovernance(address newGovernace) public virtual onlyOwner {
        require(newGovernace != address(0), "Governace: new owner is the zero address");
        _transferGovernance(newGovernace);
    }
    
     function _transferGovernance(address newGovernace) internal virtual {
        _governance = newGovernace;
     }
     
     function governance() public view virtual returns (address) {
        return _governance;
    }
    
    /* ========== MODIFIERS ========== */
    
    modifier checkPoolOpen() {
        require(block.timestamp <= endStaking, "Error: Staking is finished");
        require(block.timestamp >= startStaking, "Error: Staking has not yet begun");
        _;
    }
    
    modifier checkStakingFinished() {
        require(block.timestamp >= endStaking, "Error: Staking period is not finished");
        _;
    }
    
    modifier checkStakingUnpaused() {
        require(paused == false, "Error: Swap is paused, try again later");
        _;
    }
    
    modifier onlyGovernance() {
        require(owner() == _msgSender() || governance() == _msgSender() , "Ownable: caller is not the owner/governance");
        _;
    }

}
// File: MetalSwap/StakingPools/StakingPoolSlowRelease.sol

// "SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.8.7;


contract StakingPoolSlowRelease is StakingPoolV2base {
    
    /* ========== STATE VARIABLES ========== */

    bool private finalized;
    uint256 public periodLockupPercent = 555555;        //range [0-100*1M]=[0-100000000], 0,555555% each day lasts for 180 days until complete unlock
    uint256 public lockupPeriod = 1 days;
    uint256 public mult = 1e6;
    
    struct RedeemData {
        bool hasBegunRedeem;
        uint256 leftOverToRedeem;
        uint256 lastRedeemTimestamp;
    }

    mapping (address => RedeemData) public userRedeemData;

    event TokensRedeemed(address user, uint256 redeemedTokens, uint256 timestamp);

    constructor(IERC20 _stakingToken) StakingPoolV2base(_stakingToken) {
    }

    function finalizePoolCreation ( uint256 _startStaking, uint256 periodInSec, uint256 amountOfRewardsTokensToSend, uint16 _slotNumber, uint256 _forSlotAmount) public override onlyGovernance nonReentrant {
        require (finalized == false, "Error: Staking Pool must be paused in order to finalize!");
        require (amountOfRewardsTokensToSend > 0, "Error: The creator must send some reward tokens to the pool in order to create it");
        require (stakingToken.transferFrom(msg.sender, address(this), amountOfRewardsTokensToSend), "Error: Reward tokens trasnfer error, cannot create pool");
        
        startStaking = _startStaking;
        
        endStaking = _startStaking + periodInSec;
        
        rewardTokensAmount = amountOfRewardsTokensToSend;
        
        emit RewardAdded(amountOfRewardsTokensToSend);
    }

    function finalizeRedeemParameters (uint256 _periodLockupPercent, uint256 _lockupPeriodInSec) public onlyGovernance nonReentrant {
        periodLockupPercent = _periodLockupPercent;
        lockupPeriod = _lockupPeriodInSec;
        finalized = true;
        paused = false;
    }

    function stake(uint256 amount, uint16 slotNumberForUser) public override nonReentrant checkPoolOpen checkStakingUnpaused{
        require(amount > 0, "Error: Cannot stake 0");
        
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Error during token transfer");
        
        tokensStakedPerUser[msg.sender] += amount;
        
        uint256 weightedAverage = calcWeightedAverage(amount);
        userWeightedAverage[msg.sender] += weightedAverage;
        
        poolWeightedAverage += weightedAverage;
        stakedTokensTotal += amount;

        userOperations[msg.sender].push(Stake(amount, block.timestamp));

        userRedeemData[msg.sender] = RedeemData(false, 0, 0);
        
        emit Staked(msg.sender, amount);
    }

    function exit() public override nonReentrant checkStakingFinished checkStakingUnpaused {    

        require (tokensStakedPerUser[msg.sender] > 0, "Error: user has not staked");
        require (block.timestamp >= (userRedeemData[msg.sender].lastRedeemTimestamp + lockupPeriod), "Error: not enough time has passed from the last call to receiveNewTokens");

        if (!userRedeemData[msg.sender].hasBegunRedeem){
            userRedeemData[msg.sender].hasBegunRedeem = true;
            userRedeemData[msg.sender].lastRedeemTimestamp = endStaking;
            userRedeemData[msg.sender].leftOverToRedeem = tokensStakedPerUser[msg.sender] + calcReward(msg.sender);
        }

        uint256 tokensToRedeem =  (tokensStakedPerUser[msg.sender] + calcReward(msg.sender)) * periodLockupPercent * ((block.timestamp - userRedeemData[msg.sender].lastRedeemTimestamp) / lockupPeriod) / (mult * 100);

        if (tokensToRedeem >= userRedeemData[msg.sender].leftOverToRedeem){
            tokensToRedeem = userRedeemData[msg.sender].leftOverToRedeem;
            userRedeemData[msg.sender].leftOverToRedeem = 0;
        } else {
            userRedeemData[msg.sender].leftOverToRedeem = userRedeemData[msg.sender].leftOverToRedeem - tokensToRedeem;
        }

        require (tokensToRedeem > 0, "Error: you have not matured any tokens to redeem yet");
        userRedeemData[msg.sender].lastRedeemTimestamp = block.timestamp - ((block.timestamp - userRedeemData[msg.sender].lastRedeemTimestamp ) % lockupPeriod);
        require (stakingToken.transfer(msg.sender, tokensToRedeem),
            "Token transfer error: unable to send tokens to msg.sender address!");
        emit TokensRedeemed(msg.sender, tokensToRedeem, block.timestamp);   
        

        if (userRedeemData[msg.sender].leftOverToRedeem == 0){
            tokensStakedPerUser[msg.sender] = 0;
            userWeightedAverage[msg.sender] = 0;
        }
    }

    /* ========== VIEWS ========== */

    function getRedeemUserData (address user) public view returns (bool hasBegunRedeem, uint256 leftOverToRedeem, uint256 lastRedeemTimestamp){
        return (
            userRedeemData[user].hasBegunRedeem,
            userRedeemData[user].leftOverToRedeem,
            userRedeemData[user].lastRedeemTimestamp
        );
    }

    function calcReward (address user) public override view returns (uint256 reward) {
        if(poolWeightedAverage>0){
            return userWeightedAverage[user] * rewardTokensAmount / poolWeightedAverage;
        }
        return 0;
    }

    function calcCurrentlyMaturedReward (address user) public view returns (uint256 tokensToRedeem) {
        
        if (block.timestamp >= endStaking) {
            
            if (userRedeemData[user].hasBegunRedeem) {
                tokensToRedeem =  (tokensStakedPerUser[user] + calcReward(user)) * periodLockupPercent * ((block.timestamp - userRedeemData[user].lastRedeemTimestamp) / lockupPeriod) / (mult * 100);
                if (tokensToRedeem >= userRedeemData[user].leftOverToRedeem){
                    tokensToRedeem = userRedeemData[user].leftOverToRedeem;
                }
            } else {
                tokensToRedeem =  (tokensStakedPerUser[user] + calcReward(user)) * periodLockupPercent * ((block.timestamp - endStaking) / lockupPeriod) / (mult * 100);
                if (tokensToRedeem >= (tokensStakedPerUser[user] + calcReward(user))){
                    tokensToRedeem = (tokensStakedPerUser[user] + calcReward(user));
                }
            }
            return tokensToRedeem;
        }
        return 0;
    }

}
