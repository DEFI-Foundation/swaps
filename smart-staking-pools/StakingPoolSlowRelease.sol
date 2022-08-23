// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import './StakingPoolV2Base.sol';

contract StakingPoolSlowRelease is StakingPoolV2base {
    
    /* ========== STATE VARIABLES ========== */

    bool private finalized;
    uint256 public periodLockupPercent = 555555;        //range [0-100*1M]=[0-100000000], 0,555555% each day lasts for 180 days until complete unlock
    uint256 public lockupPeriod = 1 days;
    uint256 public constant mult = 1e6;
    
    struct RedeemData {
        bool hasBegunRedeem;
        uint256 leftOverToRedeem;
        uint256 lastRedeemTimestamp;
    }

    mapping (address => RedeemData) public userRedeemData;


    event FinalizeRedeemParameters(uint256 _periodLockupPercent, uint256 _lockupPeriodInSec,bool finalized, bool paused);

    event TokensRedeemed(address user, uint256 redeemedTokens, uint256 timestamp);

    constructor(IERC20 _stakingToken) StakingPoolV2base(_stakingToken) {
    }

    function finalizePoolCreation ( uint256 _startStaking, uint256 periodInSec, uint256 amountOfRewardsTokensToSend, uint16 _slotNumber, uint256 _forSlotAmount) external override onlyGovernance nonReentrant {
        require (!finalized, "Error: Staking Pool cannot already be finalized in order to finalize!");
        require (amountOfRewardsTokensToSend > 0, "Error: The creator must send some reward tokens to the pool in order to create it");
        require (stakingToken.transferFrom(msg.sender, address(this), amountOfRewardsTokensToSend), "Error: Reward tokens transfer error, cannot create pool");
        
        startStaking = _startStaking;
        
        endStaking = _startStaking + periodInSec;
        
        rewardTokensAmount = amountOfRewardsTokensToSend;
        
        emit RewardAdded(amountOfRewardsTokensToSend);
    }

    function finalizeRedeemParameters (uint256 _periodLockupPercent, uint256 _lockupPeriodInSec) external onlyGovernance nonReentrant {
        periodLockupPercent = _periodLockupPercent;
        lockupPeriod = _lockupPeriodInSec;
        finalized = true;
        paused = false;
        emit FinalizeRedeemParameters( _periodLockupPercent,  _lockupPeriodInSec, finalized,  paused);
    }

    function stake(uint256 amount, uint16 slotNumberForUser) external override nonReentrant checkPoolOpen checkStakingUnpaused{
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

        uint256 tokensToRedeem =  (tokensStakedPerUser[msg.sender] + calcReward(msg.sender)) * periodLockupPercent * (block.timestamp - userRedeemData[msg.sender].lastRedeemTimestamp) / (mult * 100 * lockupPeriod);

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

    function getRedeemUserData (address user) external view returns (bool hasBegunRedeem, uint256 leftOverToRedeem, uint256 lastRedeemTimestamp){
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

    function calcCurrentlyMaturedReward (address user) external view returns (uint256 tokensToRedeem) {
        
        if (block.timestamp >= endStaking) {
            
            if (userRedeemData[user].hasBegunRedeem) {
                tokensToRedeem = (tokensStakedPerUser[user] + calcReward(user)) * periodLockupPercent * (block.timestamp - userRedeemData[user].lastRedeemTimestamp) / (mult * 100 * lockupPeriod);
                if (tokensToRedeem >= userRedeemData[user].leftOverToRedeem){
                    tokensToRedeem = userRedeemData[user].leftOverToRedeem;
                }
            } else {
                tokensToRedeem =  (tokensStakedPerUser[user] + calcReward(user)) * periodLockupPercent * (block.timestamp - endStaking) / (mult * 100 * lockupPeriod);
                if (tokensToRedeem >= (tokensStakedPerUser[user] + calcReward(user))){
                    tokensToRedeem = (tokensStakedPerUser[user] + calcReward(user));
                }
            }
            return tokensToRedeem;
        }
        return 0;
    }

}
