// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;

import "./NFTGeneratorSupport.sol";
import "./NFTBaseChips.sol";
import  "./NFTGenerator.sol";
import  "./URIInfo.sol";

import "@openzeppelin/contracts/access/Ownable.sol";


contract NFTDescriptor is Ownable{

    struct nftParam {
        string rarityGem;
        string rarityBorder;
        string rarityWave;
        string raritySparkle;
        string rarityWaveAnimation;
        string raritySparkleAnimation;
        string color1;
        string color2;
    }


    string private borderDiamond = "#CAE7F0";
    string private borderGold = "#E9AE17";
    string private borderSilver = "#A7A7A7";
    string private borderBronze = "#C86912";

    string[] private colors = ["#eb4034", "#9ceb34", "#ebcd34", "#e186eb", "#811ce6", "#19e6e6", "#8f0b19", "#0e420b", "#2b1306"];

    mapping(address => string) public currencyChip;
    mapping(address => uint256) public advantageFactor;

    address public addressETH = address(0);
    address public nftGenerator;

    constructor(address _nftGenerator, address addressWBTC , address addressUSDT , uint256 advantageFactorETH, uint256 advantageFactorWBTC , uint256 advantageFactorUSDT) {
        nftGenerator =_nftGenerator;
        currencyChip[addressETH] = NFTBaseChips.chipETH;
        currencyChip[addressUSDT] =NFTBaseChips.chipUSDT;
        currencyChip[addressWBTC] =NFTBaseChips.chipWBTC;
        advantageFactor[addressUSDT] = advantageFactorUSDT;
        advantageFactor[addressETH] = advantageFactorETH;
        advantageFactor[addressWBTC] = advantageFactorWBTC;

    }

    function generateSvg(address _liquidityToken, address _liquidityPool, uint256 _initialLiquidity, uint256 currentLiquidity, uint256 _nftId, uint256 _creationTimestamp, address _creator, address _currentOwner) public view returns (string memory NFTuri) {
       
        nftParam memory toInput = generateSVGParam(_liquidityToken, _initialLiquidity, _nftId, _creationTimestamp, _creator);


        string memory image = NFTGenerator(nftGenerator).generateSVG(toInput, currencyChip[_liquidityToken], _nftId);
    
        NFTuri = string(abi.encodePacked (
                        '{"name":"',

                            URIInfo.generateURIName(_liquidityToken),
                            '", "description":"',

                            
                            URIInfo.generateURIDescription(_liquidityToken, _liquidityPool, _currentOwner, _nftId, currentLiquidity)
                            
                        ));
        {                
        NFTuri = string(abi.encodePacked (NFTuri,

                            '", "image": "',
                            'data:image/svg+xml;base64,'));
        }
        {
        NFTuri = string(abi.encodePacked (NFTuri, image ,     
                            
                            '"}'
                        ));
        }
        return NFTuri;            
    }


    function generateSVGParam(address _liquidityToken, uint256 _amount, uint256 _nftId, uint256 _creationTimestamp, address _creator) public view returns (nftParam memory  nftParamGenerate)  {

        require (advantageFactor[_liquidityToken] != 0, "Error: Liquidity Token pass not valid ");

        (uint16 symbol, uint16 border, uint16 effects) = pseudoRandom (_liquidityToken, _amount, _nftId, _creationTimestamp, _creator);

        (string memory rarityGem, string memory rarityBorder, string memory rarityWave, string memory raritySparkle, string memory rarityWaveAnimation, string memory raritySparkleAnimation) = generateRarityFeatures (symbol, border, effects);

        (string memory color1, string memory color2) = generateColorHex(symbol, border);

        return nftParam (
            rarityGem,
            rarityBorder,
            rarityWave,
            raritySparkle,
            rarityWaveAnimation,
            raritySparkleAnimation,
            color1,
            color2
        );

    }

    function setCurrencyChip (address _token, string memory _currencyChip) public onlyOwner {
        currencyChip[_token] = _currencyChip;
    }

    function setCurrencyAdvantageFactor (address _token, uint256 _advantageFactor) public onlyOwner {
        advantageFactor[_token] = _advantageFactor;
    }

    function generateColorHex (uint16 _colorSeed1, uint16 _colorSeed2) internal view returns (string memory color1, string memory color2) {
        while (_colorSeed1 % 9 == _colorSeed2 % 9) {
            _colorSeed2 = uint16(uint256(keccak256(abi.encodePacked(_colorSeed2))));
        }
        return (colors[_colorSeed1 % 9], colors[_colorSeed2 % 9]);
    }

    function pseudoRandom (address _token, uint256 _amount, uint256 _nftId, uint256 _creationTimestamp, address _creator) public view returns ( uint16, uint16, uint16) {

        require(advantageFactor[_token] != 0, "Error: Liquidity Token pass not valid ");
        uint16 temp;
        uint16 advantage = uint16(_amount / advantageFactor[_token]);

        uint16 h = uint16(uint256(keccak256(abi.encodePacked(_creationTimestamp, _creator, _token, _amount, _nftId))));
        uint16 k = uint16(uint256(keccak256(abi.encodePacked(_creationTimestamp, _creator, _token, _amount, _nftId, h))));
        uint16 z = uint16(uint256(keccak256(abi.encodePacked(_creationTimestamp, _creator, _token, _amount, _nftId, k)))); 

        for(uint256 i=0; i<=advantage; i++){
            temp = uint16(uint256(keccak256(abi.encodePacked(_creationTimestamp, _creator, _token, _amount, _nftId, i)))); 
            
            if (temp < z) {
                z = temp;
            } 
        }

        return (h, k, z);
    }

    function generateRarityFeatures (uint16 symbol, uint16 border, uint16 effects) internal view returns (string memory rarityGem, string memory rarityBorder, string memory rarityWave, string memory raritySparkle, string memory rarityWaveAnimation, string memory raritySparkleAnimation) {
        
        if (symbol <= 3276) {               //5%
            rarityGem = NFTGeneratorSupport.symbolDiamond;
        } else if (symbol <= 9830) {        //15%
            rarityGem = NFTGeneratorSupport.symbolEmerald;
        } else if (symbol <= 26214) {       //20%
            rarityGem = NFTGeneratorSupport.symbolAmethyst;
        } else {                            //60%
            rarityGem = NFTGeneratorSupport.symbolIngot;
        }

        if (border <= 6553) {               //10%
            rarityBorder = borderDiamond;
        } else if (border <= 13107) {       //20%
            rarityBorder = borderGold;
        } else if (border <= 19660) {       //30%
            rarityBorder = borderSilver;
        } else {                            //40%
            rarityBorder = borderBronze;
        }

        if (effects <= 13107) {                           
            rarityWave = NFTGeneratorSupport.lightWaves;                //20%
            rarityWaveAnimation = NFTGeneratorSupport.wavesAnimationStyle;
            if(effects <= 3276) {
                raritySparkle = NFTGeneratorSupport.sparkleBackground;  //5%
                raritySparkleAnimation = NFTGeneratorSupport.sparkleBackgroundStyle;
            }
        }

        return ( 
            rarityGem,
            rarityBorder,
            rarityWave,
            raritySparkle,
            rarityWaveAnimation,
            raritySparkleAnimation
        );

    }


}