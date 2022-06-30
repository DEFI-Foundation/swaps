// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./HexStrings.sol";

library URIInfo {
    
    using HexStrings for uint256;


    function generateURIName(address liquidityToken) internal view returns (string memory) {
        
        string memory name =  "Ethereum";
        string memory symbol = "ETH";

        
        if(liquidityToken != address(0)){
             name =  ERC20(liquidityToken).name();
             symbol = ERC20(liquidityToken).symbol();
        }

        return
            string(
                abi.encodePacked(
                    'MetalSwap - ',
                    escapeQuotes(name),
                    ' - ',
                    escapeQuotes(symbol)
                )
            );
    }


    function generateURIDescription(address liquidityToken, address liquidityPool, address currentOwner, uint256 tokenId, uint256 currentLiquidity ) internal view returns (string memory) {

        string memory symbol = "ETH";

        if(liquidityToken != address(0)){
            symbol = ERC20(liquidityToken).symbol();
        }

        return 
            string(
                abi.encodePacked(
                    'This NFT represents a liquidity position in the ',
                    escapeQuotes(symbol),
                    ' MetalSwap liquidity pool. ',
                    'The owner of this NFT can modify or redeem the position.\\n',
                    '\\nCurrent owner: ',
                    addressToString(currentOwner),
                    '\\nCurrent liquidity: ',
                    Strings.toString(currentLiquidity),
                    '\\nPool Address: ',
                    addressToString(liquidityPool),
                    '\\nToken ID: ',
                    Strings.toString(tokenId),
                    '\\n\\n',
                    unicode'⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token address match the expected tokens, as token symbols may be imitated.'
                )
            );
    }

    function generateURIDescriptionTEST () internal view returns (string memory) {
        return generateURIDescription(0x0000000000000000000000000000000000000000, 0xAA0A0a0a660c941f6792359a109B95242a3F11d4, 0xb0E2790707c1627B96e26e71d52e94CbF5274190, 125, 10000000000000000000000);
    }


    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = '\\';
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }


      function addressToString(address addr) internal pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }

}