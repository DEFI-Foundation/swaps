// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/NFTDescriptor.sol";

abstract contract MetalSwapPoolAbstract is
    Ownable,
    ReentrancyGuard,
    ERC721Enumerable 
    {

    string public description;
    string public terms_of_use;

    uint256 public rewardTokensPerDay;
    uint256 public lockedAmount;
    uint256 public lockupPeriod = 1 hours;
    uint256 public secondsInADay = 86400;       //only for testing purposes
    uint256 public lockedPremium;

    uint256 public minLiquidity;   

    ERC20 public token;
    ERC20 public rewardToken;

 
    bool public paused = false;

    address[] public swapPairsManagement;

    struct Position {
        address creator;
        address owner;
        uint256 liquidityCreation;
        uint256 liquidity;
        uint256 creationTimestamp;
        uint256 lockupTimestamp;
        uint256 rewardTimestamp;
    }

    mapping(uint256 => Position) public _positions;
    /// @dev The ID of the next token that will be minted. Skips 0
    uint176 public nextId = 1;
    address public tokenDescriptor;
    uint256 public totalLiquidity;

    event NFTCreated (address indexed account, uint256 indexed tokenId, uint256 providedLiquidity);
    event PositionModified (address indexed account, uint256 indexed tokenId, uint256 newLiquidity);
    
    constructor(ERC20 _token, ERC20 _rewardToken, address _tokenDescriptorAddress,uint256 _minLiquidity) {
        rewardToken = _rewardToken;
        token = _token;
        tokenDescriptor = _tokenDescriptorAddress;
        minLiquidity = _minLiquidity;
    }

    function positions(uint256 tokenId)
        public
        view
        returns (
            address owner,
            uint256 liquidity ,
            uint256 creationTimestamp,
            uint256 lockupTimestamp,
            address creator,
            uint256 liquidityCreation
        )
    {
        Position memory position = _positions[tokenId];
        require(exist(tokenId), 'Invalid token ID');
        return (
            position.owner,
            position.liquidity,
            position.creationTimestamp,
            position.lockupTimestamp,
            position.creator,
            position.liquidityCreation
 
        );
    }

    function changeNFTDescriptor (address _tokenDescriptor) public onlyHighLevelAccess {
        tokenDescriptor = _tokenDescriptor;
    }

    function finalizePool (uint256 amountOfRewardsTokensToSend, uint256 _rewardTokensPerDay, string memory _description, string memory _termsOfUse) public onlyHighLevelAccess {
        require (amountOfRewardsTokensToSend > 0, "Error: The creator must send some reward tokens to the pool in order to create it");
        require (rewardToken.transferFrom(msg.sender, address(this), amountOfRewardsTokensToSend), "Error: Reward tokens transfer error, cannot finalize pool");
        rewardTokensPerDay = _rewardTokensPerDay;

        description = _description;
        terms_of_use = _termsOfUse;
    }

    receive() external payable {}

    function createNewPosition(uint256 _amount) public payable nonReentrant virtual returns (uint256 mint) {
    }

    function addLiquidity(uint256 _amount, uint256 _tokenId) public payable nonReentrant virtual returns (uint256 liquidityAdded) {
    }

    function removeLiquidity(uint256 _amount, uint256 _tokenId) public nonReentrant virtual returns (uint256 liquidityToWithdraw) {
    }

    function redeemReward(uint256 _tokenID) public returns (uint256 rewardAmount) {     //toDO: to change to ERC721
        
        rewardAmount = calcReward(_tokenID);

        if(rewardAmount == 0){
            if(_positions[_tokenID].rewardTimestamp != 0){
                _positions[_tokenID].rewardTimestamp = block.timestamp;
            }
            return 0;
        }

        _positions[_tokenID].rewardTimestamp = block.timestamp;
        
        require(rewardToken.transfer(msg.sender, rewardAmount), "Error: pool can't send reward");

        return rewardAmount;
    }

    function calcPenalties(uint256 provideAmount, uint256 _tokenID ) public view returns (uint256 penalties ) {
        uint256 endLockupPeriod = _positions[_tokenID].lockupTimestamp;
        if (block.timestamp > endLockupPeriod) {
            return 0;
        }

        return provideAmount * (endLockupPeriod - block.timestamp) /lockupPeriod;
    }

    function calcReward(uint256 _tokenID) public view returns (uint256 reward) {
        reward = 0;
        if( (_positions[_tokenID].rewardTimestamp!= 0) && (_positions[_tokenID].rewardTimestamp + secondsInADay < block.timestamp) ) {
            uint256 timePassedFromLastRedeem = block.timestamp - _positions[_tokenID].rewardTimestamp;
            reward = timePassedFromLastRedeem * rewardTokensPerDay * _positions[_tokenID].liquidity / totalLiquidity / secondsInADay;
        }
        return reward;
    }

    function lock(uint256 amount) external  onlyHighLevelAccess {
        /*require(
            lockedAmount+(amount)*(10)/(totalPoolBalance()) < 8,
            "Pool Error: You are trying to unlock more funds than have been locked for your contract. Please lower the amount."
        );*/
        lockedAmount = lockedAmount+(amount);
    }

    function unlock(uint256 amount) external onlyHighLevelAccess {
        require(lockedAmount >= amount, "Pool Error: You are trying to unlock more funds than have been locked for your contract. Please lower the amount.");
        lockedAmount = lockedAmount - amount;
    }

    function sendPremium(uint256 premium) external virtual payable onlyHighLevelAccess {
    }

    function unlockPremium(uint256 amount) external onlyHighLevelAccess {
        require(lockedPremium >= amount, "Pool Error: You are trying to unlock more premiums than have been locked for the contract. Please lower the amount.");
        lockedPremium = lockedPremium-(amount);
    }

    function send(address payable to, uint256 amount) external virtual onlyHighLevelAccess {
    }
    
    function sendProfit(address payable to, uint256 amount) external virtual onlyHighLevelAccess {
    }
    
    function availableBalance() public view returns (uint256 balance) {
        if (totalPoolBalance() >= lockedAmount) {
            return totalPoolBalance() - (lockedAmount);
        }
        return 0;


    }

    function totalPoolBalance() public view virtual returns (uint256 balance) {
    }

    function addSwapPairsManagement (address newPairAddress) public onlyOwner {
        require(!verifySwapPairsManagement(newPairAddress), "Address to add already has swapManagement level access");
        swapPairsManagement.push(newPairAddress);
    }

    function removeSwapPairsManagement (address toDeleteAddress) public onlyOwner {
        require (verifySwapPairsManagement(toDeleteAddress), "Error on removeSwapPairsManagement: toDeleteAddress is not listed as swapManagement");
        uint256 i;
        for(i=0; i<swapPairsManagement.length; i++){
            if(swapPairsManagement[i] == toDeleteAddress){
                swapPairsManagement[i] = swapPairsManagement[swapPairsManagement.length-1];
            }
        }
        swapPairsManagement.pop();
    }

    function verifySwapPairsManagement (address toCheck) public view returns (bool isSwapManagement) {
        uint256 i;
        for(i=0; i<swapPairsManagement.length; i++){
            if(swapPairsManagement[i] == toCheck){
                return true;
            }
        }
        return false;
    }

    function changeDescriptionAndTOU (string memory _description, string memory _termsOfUse) public onlyHighLevelAccess {
        description = _description;
        terms_of_use = _termsOfUse;
    } 

    function setMinLiquidity(uint256 _minLiquidity)public onlyHighLevelAccess {
        minLiquidity = _minLiquidity;
    }
    
    function setLockupPeriod(uint256 value) external  onlyHighLevelAccess {
        require (value <= 60 days, "Lockup period is too large");                    //toDo
        lockupPeriod = value;
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
                require (assetsToWithdraw[i].transfer(msg.sender, assetsToWithdraw[i].balanceOf(address(this))), "Error during token transfer");
            }
        }
    }

    function setRewardTokensPerDay (uint256 newRewardTokenPerDayAmount) public onlyHighLevelAccess {
        rewardTokensPerDay = newRewardTokenPerDayAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
          super._beforeTokenTransfer(from, to, tokenId);
          
         _positions[tokenId].owner = to;
    }
    
    modifier onlySwapPairsManagement () {
        require(verifySwapPairsManagement (_msgSender()), "Error: msg.sender has not swapManagement level access");
        _;        
    }

    modifier onlyHighLevelAccess () {
        require( (verifySwapPairsManagement(_msgSender())) || (_msgSender() == owner()) , "Error: msg.sender has not high level access");
        _;        
    }

    modifier checkSCUnpaused() {
        require((paused == false) , "Error: smart contract is paused!");
        _;
    }

    function exist (uint256 tokenId) public view returns (bool exists) {
        if (_positions[tokenId].owner != address(0)) {
            return true;
        }
        return false;
    }

    function tokenURI (uint256 tokenId) public view override returns (string memory tokenURIResult) {
        require(exist(tokenId), "Token ID does not match any existing liquidity NFT");
        return NFTDescriptor(tokenDescriptor).generateSvg(
                            address(token),
                            address(this),
                            _positions[tokenId].liquidityCreation,
                            _positions[tokenId].liquidity, 
                            tokenId, 
                            _positions[tokenId].creationTimestamp, 
                            _positions[tokenId].creator,
                            _positions[tokenId].owner);
    }
    
}