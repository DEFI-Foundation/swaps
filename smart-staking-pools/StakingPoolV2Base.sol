// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

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
    event PauseStaking();
    event UnpauseStaking();
    event SetTime(uint256 initTimestamp, uint256 endTimestamp);
    event ClosePool(bool paused);
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event TransferGovernance(address newGovernace);
    event Exit(address indexed user, uint256 stakedTokens, uint256 reward);

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20 _stakingToken) {
        stakingToken = _stakingToken;
        _transferGovernance(_msgSender());
        paused = true;
    }

    /* ========== FUNCTIONS ========== */

    function finalizePoolCreation(
        uint256 _startStaking,
        uint256 periodInSec,
        uint256 amountOfRewardsTokensToSend,
        uint16 _slotNumber,
        uint256 _forSlotAmount
    ) external virtual onlyGovernance nonReentrant {
        require(
            !finalized,
            'Error: Staking Pool cannot already be finalized in order to finalize!'
        );
        require(
            amountOfRewardsTokensToSend > 0,
            'Error: The creator must send some reward tokens to the pool in order to create it'
        );
        require(
            stakingToken.transferFrom(
                msg.sender,
                address(this),
                amountOfRewardsTokensToSend
            ),
            'Error: Reward tokens transfer error, cannot create pool'
        );

        startStaking = _startStaking;

        endStaking = _startStaking + periodInSec;

        rewardTokensAmount = amountOfRewardsTokensToSend;

        paused = false;
        finalized = true;

        emit RewardAdded(amountOfRewardsTokensToSend);
    }

    function stake(uint256 amount, uint16 slotNumberForUser)
        external
        virtual
        nonReentrant
        checkPoolOpen
        checkStakingUnpaused
    {
        require(amount > 0, 'Error: Cannot stake 0');

        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            'Error during token transfer'
        );

        tokensStakedPerUser[msg.sender] += amount;

        uint256 weightedAverage = calcWeightedAverage(amount);
        userWeightedAverage[msg.sender] += weightedAverage;

        poolWeightedAverage += weightedAverage;
        stakedTokensTotal += amount;

        userOperations[msg.sender].push(Stake(amount, block.timestamp));

        emit Staked(msg.sender, amount);
    }

    function exit()
        public
        virtual
        nonReentrant
        checkStakingFinished
        checkStakingUnpaused
    {
        uint256 stakedTokens = tokensStakedPerUser[msg.sender];
        uint256 reward = calcReward(msg.sender);
        require(stakedTokens > 0, 'Error: Cannot get reward = 0');
        require(reward > 0, 'Error: Cannot get reward = 0');
        tokensStakedPerUser[msg.sender] = 0;
        userWeightedAverage[msg.sender] = 0;
        require(
            stakingToken.transfer(msg.sender, (stakedTokens + reward)),
            'Error during the withdrawal of user reward'
        );
        emit Exit(msg.sender, stakedTokens, reward);
    }

    function addRewardTokensAmount(uint256 amountToAdd)
        external
        onlyGovernance
        nonReentrant
    {
        require(
            stakingToken.transferFrom(msg.sender, address(this), amountToAdd),
            'Error during the token reward increase transaction!'
        );
        rewardTokensAmount += amountToAdd;
        emit RewardAdded(amountToAdd);
    }

    function setTime(uint256 initTimestamp, uint256 endTimestamp)
        external
        onlyGovernance
    {
        if (endTimestamp > initTimestamp) {
            startStaking = initTimestamp;
            endStaking = endTimestamp;
        }
        emit SetTime(initTimestamp, endTimestamp);
    }

    function closePool() public onlyGovernance nonReentrant {
        paused = true;
        require(
            stakingToken.transfer(
                msg.sender,
                stakingToken.balanceOf(address(this))
            ),
            'Error during token transfer'
        );
        emit ClosePool(paused);
    }

    function pauseStaking() public onlyGovernance {
        paused = true;
        emit PauseStaking();
    }

    function unpauseStaking() public onlyGovernance {
        paused = false;
        emit UnpauseStaking();
    }

    /* ========== VIEWS ========== */

    function calcWeightedAverage(uint256 amount)
        public
        view
        returns (uint256 weightedAverage)
    {
        if (endStaking > startStaking) {
            return
                (amount * (endStaking - block.timestamp)) /
                (endStaking - startStaking);
        }
        return 0;
    }

    function calcReward(address user)
        public
        view
        virtual
        returns (uint256 reward)
    {
        if (poolWeightedAverage > 0) {
            return
                (userWeightedAverage[user] * rewardTokensAmount) /
                poolWeightedAverage;
        }
        return 0;
    }

    function canIStakeNow() public view returns (bool poolReady) {
        if (
            (!paused) &&
            (block.timestamp >= startStaking) &&
            (block.timestamp <= endStaking)
        ) {
            return true;
        }
        return false;
    }

    function canIExitPoolNow() public view returns (bool poolReady) {
        if (block.timestamp >= endStaking) {
            return true;
        }
        return false;
    }

    function getPoolUserData(address user)
        public
        view
        returns (uint256 userStakedTokens, uint256 userReward)
    {
        return (tokensStakedPerUser[user], calcReward(user));
    }

    function getStakingPeriod() public view returns (uint256, uint256) {
        return (startStaking, endStaking);
    }

    function transferGovernance(address newGovernace)
        external
        virtual
        onlyOwner
    {
        require(
            newGovernace != address(0),
            'Error on _transferGovernance: new owner cannot be zero address'
        );
        _transferGovernance(newGovernace);
        emit TransferGovernance(newGovernace);
    }

    function _transferGovernance(address newGovernace) private {
        require(
            newGovernace != address(0),
            'Error on _transferGovernance: new owner cannot be zero address'
        );
        _governance = newGovernace;
    }

    function governance() public view virtual returns (address) {
        return _governance;
    }

    /* ========== MODIFIERS ========== */

    modifier checkPoolOpen() {
        require(block.timestamp <= endStaking, 'Error: Staking is finished');
        require(
            block.timestamp >= startStaking,
            'Error: Staking has not yet begun'
        );
        _;
    }

    modifier checkStakingFinished() {
        require(
            block.timestamp >= endStaking,
            'Error: Staking period is not finished'
        );
        _;
    }

    modifier checkStakingUnpaused() {
        require(!paused, 'Error: Staking period is paused, try again later');
        _;
    }

    modifier onlyGovernance() {
        require(
            owner() == _msgSender() || governance() == _msgSender(),
            'Ownable: caller is not the owner/governance'
        );
        _;
    }
}
