// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;
import "./abstract/MetalSwapPoolAbstract.sol";

contract ETHPool is MetalSwapPoolAbstract  {

    
    constructor (ERC20 _liquidityToken, ERC20 _rewardToken, address _tokenDescriptorAddress,uint256 minLiquidity) 
        MetalSwapPoolAbstract(_liquidityToken, _rewardToken, _tokenDescriptorAddress,minLiquidity) 
        ERC721 ("MetalSwap NFT xETH Liquidity Token", "NFT xETH") {

    }

    function createNewPosition (uint256 _amount) public nonReentrant checkSCUnpaused() payable override returns (uint256 newNFTId) {
        require (_amount >= minLiquidity,"Pool Error: amount is too low for create a NFT position ");
        require (_amount == msg.value,"Pool Error: you are sending a different amount than the msg.value" );
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
    
    function addLiquidity (uint256 _amount, uint256 _tokenId) public payable nonReentrant override returns (uint256 liquidityAdded){
        require (_amount == msg.value,"Pool Error: you are sending a different amount than the msg.value" );
        require (exist(_tokenId), "Token ID does not match any existing liquidity NFT");
        require (_positions[_tokenId].owner == msg.sender, "Error: msg.sender is not NFT token owner");

        redeemReward(_tokenId);     //call redeemReward BEFORE modifiying NFT position
        
        _positions[_tokenId].liquidity = _positions[_tokenId].liquidity + _amount;
        _positions[_tokenId].lockupTimestamp = block.timestamp + lockupPeriod;

        totalLiquidity += _amount;

        emit PositionModified (msg.sender, _tokenId, _amount);

        return _amount;
    }

    function removeLiquidity(uint256 _amount, uint256 _tokenId) public nonReentrant override returns (uint256 liquidityToWithdraw){
        require (exist(_tokenId), "Token ID does not match any existing liquidity NFT");
        require (_positions[_tokenId].owner == msg.sender, "Error: msg.sender is not NFT token owner");
        require (_positions[_tokenId].liquidity >= _amount, "Error: you are trying to remove more liquidity than allowed");

        redeemReward(_tokenId);     //call redeemReward BEFORE modifiying NFT position

        uint256 penalities = calcPenalties(_amount,  _tokenId);
        liquidityToWithdraw = availableBalance() * _amount / totalLiquidity;

        if (liquidityToWithdraw >= _amount) {
            liquidityToWithdraw = _amount;
        }

        require(liquidityToWithdraw > 0, "Error: amount of ETH to withdraw is too small");
        require(liquidityToWithdraw <=  _positions[_tokenId].liquidity, "Error: user is asking to withdraw more than provided");
        require(liquidityToWithdraw > penalities, "Error: your penalities are higher than the ETH to withdraw, please wait longer");
        require(totalLiquidity >= _amount, "Error: totalLiquidity to low");

        totalLiquidity = totalLiquidity - _amount;

        _positions[_tokenId].liquidity = _positions[_tokenId].liquidity - _amount;

        payable(msg.sender).transfer(liquidityToWithdraw - penalities);

        emit PositionModified (msg.sender, _tokenId, _amount);

        return liquidityToWithdraw;
    }

   
    function sendPremium(uint256 premium) external override payable onlyHighLevelAccess {
        require(premium == msg.value);
        lockedPremium = lockedPremium + (msg.value);
    }

    function send(address payable to, uint256 amount) external override onlyHighLevelAccess {
        require(to != address(0));
        require(lockedAmount >= amount, "Pool Error: You are trying to unlock more premiums than have been locked for the contract. Please lower the amount.");
        to.transfer(amount);
    }

    function sendProfit(address payable to, uint256 amount) external override onlyHighLevelAccess {
        require(to != address(0));
        require(availableBalance() >= amount, "Pool Error: You are trying to send more profit  than have been locked for the contract. Please lower the amount.");
        to.transfer(amount);
    }

    function totalPoolBalance() public view override returns (uint256 balance) {
        return (address(this)).balance;
    }
}