// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../libraries/NFTDescriptor.sol';

abstract contract MetalSwapPoolAbstract is
    Ownable,
    ReentrancyGuard,
    ERC721Enumerable
{
    string public description;
    string public terms_of_use;

    address public _governance;

    uint256 public rewardTokensPerDay;
    uint256 public lockedAmount;
    uint256 public lockupPeriod = 1 hours;
    uint256 public constant secondsInADay = 86400; //only for testing purposes
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

    event NFTCreated(
        address indexed account,
        uint256 indexed tokenId,
        uint256 providedLiquidity
    );
    event PositionModified(
        address indexed account,
        uint256 indexed tokenId,
        uint256 newLiquidity
    );
    event RedeemReward(
        uint256 _tokenID,
        address beneficiary,
        uint256 rewardAmount
    );

    event Lock(address lockFrom, uint256 lockAmount);
    event Unlock(address unlockFrom, uint256 unlockAmount);
    event UnlockPremium(address unlockPremiumFrom, uint256 amount);
    event Send(address payable to, uint256 amount);
    event SendProfit(address payable to, uint256 amount);
    event WithdrawSurplus(address payable to, uint256 amount);

    event ChangeNFTDescriptor(address _tokenDescriptor);
    event FinalizePool(
        uint256 amountOfRewardsTokensToSend,
        uint256 _rewardTokensPerDay,
        string _description,
        string _termsOfUse
    );
    event AddSwapPairsManagement(address newPairAddress);
    event RemoveSwapPairsManagement(address toRemovePairAddress);
    event ChangeDescriptionAndTOU(string _description, string _termsOfUse);
    event SetMinLiquidity(uint256 _minLiquidity);
    event SetLockupPeriod(uint256 value);
    event SetStateSC(bool state);
    event SetRewardTokensPerDay(uint256 newRewardTokenPerDayAmount);
    event TransferGovernance(address newGovernace);
    event DecommissionSC(
        address decommissionAssset,
        uint256 decommissionBalance,
        address decommissionBeneficiary
    );

    constructor(
        ERC20 _token,
        ERC20 _rewardToken,
        address _tokenDescriptorAddress,
        uint256 _minLiquidity
    ) {
        require(
            address(_rewardToken) != address(0) &&
                _tokenDescriptorAddress != address(0),
            'Error on constructor: input cannot be zero address'
        );
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
            uint256 liquidity,
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

    function changeNFTDescriptor(address _tokenDescriptor)
        external
        onlyHighLevelAccess
    {
        require(
            _tokenDescriptor != address(0),
            'Error on changeNFTDescriptor: input cannot be zero address'
        );
        tokenDescriptor = _tokenDescriptor;
        emit ChangeNFTDescriptor(_tokenDescriptor);
    }

    function finalizePool(
        uint256 amountOfRewardsTokensToSend,
        uint256 _rewardTokensPerDay,
        string memory _description,
        string memory _termsOfUse
    ) external onlyHighLevelAccess {
        require(
            amountOfRewardsTokensToSend > 0,
            'Error: The creator must send some reward tokens to the pool in order to create it'
        );
        require(
            rewardToken.transferFrom(
                msg.sender,
                address(this),
                amountOfRewardsTokensToSend
            ),
            'Error: Reward tokens transfer error, cannot finalize pool'
        );
        rewardTokensPerDay = _rewardTokensPerDay;

        description = _description;
        terms_of_use = _termsOfUse;
        emit FinalizePool(
            amountOfRewardsTokensToSend,
            _rewardTokensPerDay,
            _description,
            _termsOfUse
        );
    }

    receive() external payable {}

    function createNewPosition(uint256 _amount)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 mint)
    {}

    function addLiquidity(uint256 _amount, uint256 _tokenId)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 liquidityAdded)
    {}

    function removeLiquidity(uint256 _amount, uint256 _tokenId)
        external
        virtual
        nonReentrant
        returns (uint256 liquidityToWithdraw)
    {}

    function withdrawSurplus()
        public
        virtual
        onlyOwner
        nonReentrant
        returns (uint256 surplus)
    {}

    function redeemReward(uint256 _tokenID)
        public
        returns (uint256 rewardAmount)
    {
        rewardAmount = calcReward(_tokenID);

        if (rewardAmount == 0) {
            if (_positions[_tokenID].rewardTimestamp != 0) {
                _positions[_tokenID].rewardTimestamp = block.timestamp;
            }
            return 0;
        }

        _positions[_tokenID].rewardTimestamp = block.timestamp;

        require(
            rewardToken.transfer(msg.sender, rewardAmount),
            "Error: pool can't send reward"
        );
        emit RedeemReward(_tokenID, msg.sender, rewardAmount);
        return rewardAmount;
    }

    function calcPenalties(uint256 provideAmount, uint256 _tokenID)
        public
        view
        returns (uint256 penalties)
    {
        uint256 endLockupPeriod = _positions[_tokenID].lockupTimestamp;
        if (block.timestamp > endLockupPeriod) {
            return 0;
        }

        return
            (provideAmount * (endLockupPeriod - block.timestamp)) /
            lockupPeriod;
    }

    function calcReward(uint256 _tokenID) public view returns (uint256 reward) {
        reward = 0;
        if (
            (_positions[_tokenID].rewardTimestamp != 0) &&
            (_positions[_tokenID].rewardTimestamp + secondsInADay <
                block.timestamp)
        ) {
            uint256 timePassedFromLastRedeem = block.timestamp -
                _positions[_tokenID].rewardTimestamp;
            reward =
                (timePassedFromLastRedeem *
                    rewardTokensPerDay *
                    _positions[_tokenID].liquidity) /
                totalLiquidity /
                secondsInADay;
        }
        return reward;
    }

    function lock(uint256 amount) external onlyHighLevelAccess {
        lockedAmount = lockedAmount + amount;
        emit Lock(msg.sender, amount);
    }

    function unlock(uint256 amount) external onlyHighLevelAccess {
        require(
            lockedAmount >= amount,
            'Pool Error: You are trying to unlock more funds than have been locked for your contract. Please lower the amount.'
        );
        lockedAmount = lockedAmount - amount;
        emit Unlock(msg.sender, amount);
    }

    function unlockPremium(uint256 amount) external onlyHighLevelAccess {
        require(
            lockedPremium >= amount,
            'Pool Error: You are trying to unlock more premiums than have been locked for the contract. Please lower the amount.'
        );
        lockedPremium = lockedPremium - amount;
        emit UnlockPremium(msg.sender, amount);
    }

    function send(address payable to, uint256 amount)
        external
        virtual
        onlyHighLevelAccess
    {}

    function sendProfit(address payable to, uint256 amount)
        external
        virtual
        onlyHighLevelAccess
    {}

    function availableBalance() public view returns (uint256 balance) {
        if (totalPoolBalance() >= lockedAmount) {
            return totalPoolBalance() - (lockedAmount);
        }
        return 0;
    }

    function totalPoolBalance() public view virtual returns (uint256 balance) {}

    function addSwapPairsManagement(address newPairAddress) external onlyOwner {
        require(
            !verifySwapPairsManagement(newPairAddress),
            'Address to add already has swapManagement level access'
        );
        swapPairsManagement.push(newPairAddress);
        emit AddSwapPairsManagement(newPairAddress);
    }

    function removeSwapPairsManagement(address toDeleteAddress)
        external
        onlyOwner
    {
        require(
            verifySwapPairsManagement(toDeleteAddress),
            'Error on removeSwapPairsManagement: toDeleteAddress is not listed as swapManagement'
        );
        uint256 i;
        for (i = 0; i < swapPairsManagement.length; i++) {
            if (swapPairsManagement[i] == toDeleteAddress) {
                swapPairsManagement[i] = swapPairsManagement[
                    swapPairsManagement.length - 1
                ];
                swapPairsManagement.pop();
                emit RemoveSwapPairsManagement(toDeleteAddress);
                break;
            }
        }
    }

    function verifySwapPairsManagement(address toCheck)
        public
        view
        returns (bool isSwapManagement)
    {
        uint256 i;
        for (i = 0; i < swapPairsManagement.length; i++) {
            if (swapPairsManagement[i] == toCheck) {
                return true;
            }
        }
        return false;
    }

    function changeDescriptionAndTOU(
        string memory _description,
        string memory _termsOfUse
    ) external onlyHighLevelAccess {
        description = _description;
        terms_of_use = _termsOfUse;
        emit ChangeDescriptionAndTOU(_description, _termsOfUse);
    }

    function setMinLiquidity(uint256 _minLiquidity)
        external
        onlyHighLevelAccess
    {
        minLiquidity = _minLiquidity;
        emit SetMinLiquidity(_minLiquidity);
    }

    function setLockupPeriod(uint256 value) external onlyHighLevelAccess {
        require(value <= 60 days, 'Lockup period is too large');
        lockupPeriod = value;
        emit SetLockupPeriod(value);
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
                    'Error on decommissionSC Pool: during token transfer'
                );
                emit DecommissionSC(
                    address(assetsToWithdraw[i]),
                    assetsToWithdraw[i].balanceOf(address(this)),
                    msg.sender
                );
            }
        }
    }

    function setRewardTokensPerDay(uint256 newRewardTokenPerDayAmount)
        external
        onlyHighLevelAccess
    {
        rewardTokensPerDay = newRewardTokenPerDayAmount;
        emit SetRewardTokensPerDay(newRewardTokenPerDayAmount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        _positions[tokenId].owner = to;
    }

    function _transferGovernance(address newGovernance) private {
        require(
            newGovernance != address(0),
            'Error on _transferGovernance: new owner cannot be zero address'
        );
        _governance = newGovernance;
    }

    function governance() public view virtual returns (address) {
        return _governance;
    }

    function transferGovernance(address newGovernace) external onlyOwner {
        require(
            newGovernace != address(0),
            'Error on transferGovernance: new owner cannot be the null address'
        );
        _transferGovernance(newGovernace);
        emit TransferGovernance(newGovernace);
    }

    modifier onlyHighLevelAccess() {
        require(
            (verifySwapPairsManagement(_msgSender())) ||
                (_msgSender() == owner()) ||
                (_msgSender() == governance()),
            'Error: msg.sender has not high level access'
        );
        _;
    }

    modifier checkSCUnpaused() {
        require((!paused), 'Error: smart contract is paused!');
        _;
    }

    function exist(uint256 tokenId) public view returns (bool exists) {
        if (_positions[tokenId].owner != address(0)) {
            return true;
        }
        return false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory tokenURIResult)
    {
        require(
            exist(tokenId),
            'Token ID does not match any existing liquidity NFT'
        );
        return
            NFTDescriptor(tokenDescriptor).generateSvg(
                address(token),
                address(this),
                _positions[tokenId].liquidityCreation,
                _positions[tokenId].liquidity,
                tokenId,
                _positions[tokenId].creationTimestamp,
                _positions[tokenId].creator,
                _positions[tokenId].owner
            );
    }
}
