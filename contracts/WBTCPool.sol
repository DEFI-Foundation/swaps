// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./abstract/MetalSwapPoolAbstract.sol";

contract WBTCPool is MetalSwapPoolAbstract  {

    using SafeERC20 for ERC20;
    
    constructor (ERC20 _liquidityToken, ERC20 _rewardToken, address _tokenDescriptorAddress,uint256 minLiquidity) 
        MetalSwapPoolAbstract(_liquidityToken, _rewardToken, _tokenDescriptorAddress,minLiquidity) 
        ERC721 ("MetalSwap NFT xWBTC Liquidity Token", "NFT xWBTC") {

    }

    function createNewPosition (uint256 _amount) public payable nonReentrant checkSCUnpaused() override returns (uint256 newNFTId) {
        require (_amount >= minLiquidity,"Pool Error: amount is too low for create a NFT position ");
        require (msg.value == 0,"Pool Error: you are sending ETH value to a ERC20 Pool" );
        ERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _positions[nextId] = Position  (
                                            msg.sender,
                                            msg.sender,
                                            _amount,
                                            _amount,
                                            block.timestamp,
                                            block.timestamp + lockupPeriod,
                                            block.timestamp
                                        );

        _safeMint(msg.sender, nextId);
        emit NFTCreated (msg.sender, nextId, _amount);
        totalLiquidity += _amount;
        nextId ++;
        return nextId-1;
    }

    function addLiquidity (uint256 _amount, uint256 _tokenId) public payable nonReentrant checkSCUnpaused() override returns (uint256 liquidityAdded){
        require (msg.value == 0,"Pool Error: you are sending ETH value to a ERC20 Pool" );
        require (exist(_tokenId), "Token ID does not match any existing liquidity NFT");
        require (_positions[_tokenId].owner == msg.sender, "Error: msg.sender is not NFT token owner");
        ERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        redeemReward(_tokenId);     //call redeemReward BEFORE modifiying NFT position
        
        _positions[_tokenId].liquidity = _positions[_tokenId].liquidity + _amount;
        _positions[_tokenId].lockupTimestamp = block.timestamp + lockupPeriod;

        totalLiquidity += _amount;

        emit PositionModified (msg.sender, _tokenId, _amount);

        return _amount;
    }

    function removeLiquidity(uint256 _amount, uint256 _tokenId) public nonReentrant checkSCUnpaused() override returns (uint256 liquidityToWithdraw){
        require (exist(_tokenId), "Token ID does not match any existing liquidity NFT");
        require (_positions[_tokenId].owner == msg.sender, "Error: msg.sender is not NFT token owner");
        require (_positions[_tokenId].liquidity >= _amount, "Error: you are trying to remove more liquidity than allowed");

        redeemReward(_tokenId);     //call redeemReward BEFORE modifiying NFT position

        uint256 penalities = calcPenalties(_amount,  _tokenId);
        liquidityToWithdraw = availableBalance() * _amount / totalLiquidity;

        if (liquidityToWithdraw >= _amount) {
            liquidityToWithdraw = _amount;
        }

        require(liquidityToWithdraw > 0, "Error: amount of WBTC to withdraw is too small");
        require(liquidityToWithdraw <=  _positions[_tokenId].liquidity, "Error: user is asking to withdraw more than provided");
        require(liquidityToWithdraw < penalities, "Error: your penalities are higher than the WBTC to withdraw, please wait longer");
        require(totalLiquidity >= _amount, "Error: totalLiquidity to low");

        totalLiquidity = totalLiquidity - _amount;

        _positions[_tokenId].liquidity = _positions[_tokenId].liquidity - _amount;

        ERC20(token).safeTransfer(msg.sender, liquidityToWithdraw - penalities);

        emit PositionModified (msg.sender, _tokenId, _amount);

        return liquidityToWithdraw;
    }

    function sendPremium(uint256 premium) external override payable onlyHighLevelAccess {
        lockedPremium = lockedPremium+(premium);
        ERC20(token).safeTransferFrom(msg.sender, address(this), premium);  
    }

    function send(address payable to, uint256 amount) external override onlyHighLevelAccess {
        require(to != address(0));
        require(lockedAmount >= amount, "Pool Error: You are trying to unlock more premiums than have been locked for the contract. Please lower the amount.");
        token.safeTransfer(to, amount);
    }

    function sendProfit(address payable to, uint256 amount) external override onlyHighLevelAccess {
        require(to != address(0));
        require(availableBalance() >= amount, "Pool Error: You are trying to send more profit  than have been locked for the contract. Please lower the amount.");
        token.safeTransfer(to, amount);
    }

    function totalPoolBalance() public view override returns (uint256 balance) {
        return token.balanceOf(address(this));
    }

}