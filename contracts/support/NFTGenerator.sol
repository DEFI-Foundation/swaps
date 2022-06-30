// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >= 0.8.7;

import "./NFTGeneratorSupport.sol";
import "./NFTBaseChips.sol"; 
import  "./NFTDescriptor.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTGenerator{ 

    constructor(){}

    function generateSVG (NFTDescriptor.nftParam memory nftParamGenerate, string memory chip, uint256 tokenId) public pure returns (string memory SVGImage) {

            SVGImage = string(abi.encodePacked(
                '<svg id="nft-v2" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 480 280" shape-rendering="geometricPrecision" text-rendering="geometricPrecision">'
                
                '<style>',
                    NFTGeneratorSupport.gearAnimationStyle,

                    NFTGeneratorSupport.metalSwapTitleAnimationStyle
            ));
            {
                SVGImage = string(abi.encodePacked( SVGImage,

                    nftParamGenerate.raritySparkleAnimation,
                    
                    nftParamGenerate.rarityWaveAnimation,
                '</style>'

                '<defs>',
                    NFTGeneratorSupport.generateDefinitions(nftParamGenerate.color1, nftParamGenerate.color2),
                '</defs>'
                            
                '<g id="nft-v2-base" transform="translate(.000001 0.000001)">'
                    
                    '<path id="nft-v2-base2" d="M0,10C0,4.47715,4.47715,0,10,0h445c13.807,0,25,11.1929,25,25v245c0,5.523-4.477,10-10,10h-460.00001C4.47714,280,0,275.523,0,270L0,10Z" fill="',
                    nftParamGenerate.rarityBorder,
                    '"/>'
                    '<path id="nft-v2-base-light" style="mix-blend-mode:soft-light" d="M0,10C0,4.47715,4.47715,0,10,0h445c13.807,0,25,11.1929,25,25v245c0,5.523-4.477,10-10,10h-460.00001C4.47714,280,0,275.523,0,270L0,10Z" fill="url(#nft-v2-base-light-fill)"/>'
                    '<path id="nft-v2-outer-border" d="M1,10c0-4.97057,4.02944-9,9-9h445c13.255,0,24,10.7452,24,24v245c0,4.971-4.029,9-9,9h-460.00001C5.02943,279,1,274.971,1,270L1,10Z" fill="none" stroke="#000" stroke-width="2" stroke-opacity="0.25"/>'
                    '<path id="nft-v2-color" d="M10,17c0-3.866,3.134-7,7-7h433c11.046,0,20,8.9543,20,20v233c0,3.866-3.134,7-7,7h-446c-3.866,0-7-3.134-7-7v-246Z" fill="url(#nft-v2-color-fill)"/>'
                    '<path id="nft-v2-color-light" style="mix-blend-mode:soft-light" d="M10,17c0-3.866,3.134-7,7-7h433c11.046,0,20,8.9543,20,20v233c0,3.866-3.134,7-7,7h-446c-3.866,0-7-3.134-7-7v-246Z" fill="url(#nft-v2-color-light-fill)"/>'
                    '<path id="nft-v2-inner-border" d="M11,17c0-3.3137,2.6863-6,6-6h433c10.493,0,19,8.5066,19,19v233c0,3.314-2.686,6-6,6h-446c-3.3137,0-6-2.686-6-6v-246Z" fill="none" stroke="#000" stroke-width="2" stroke-opacity="0.25"/>'
                
                    '<g id="nft-v2-lines">'
                        '<g id="nft-v2-right">'
                            '<path id="nft-v2-path1" d="M430.473,78L303.578,268h4.721L435.194,78h-4.721Z" fill-opacity="0.25"/>'
                            '<path id="nft-v2-path2" d="M411.895,78L285,268h4.721L416.616,78h-4.721Z" fill-opacity="0.25"/>'
                        '</g>'
                        '<g id="nft-v2-left">'
                            '<rect id="nft-v2-rect1" width="4" height="99" rx="0" ry="0" transform="translate(70 169)" fill-opacity="0.25"/>'
                            '<rect id="nft-v2-rect2" width="4" height="100" rx="0" ry="0" transform="translate(70 12)" fill-opacity="0.25"/>'
                        '</g>'
                    '</g>',

                    nftParamGenerate.raritySparkle
                ));
        }

        {
            SVGImage = string(abi.encodePacked( SVGImage,
                    NFTGeneratorSupport.buildTokenId(tokenId),
                    
                    '<g id="nft-v2-chip" transform="translate(35, 112)">',
                    chip
            ));
        }

        SVGImage = (string(abi.encodePacked( SVGImage,
                    '</g>'
                    '<g id="nft-v2-metalswap-logo" transform="translate(0 0.000001)">'
                        '<g id="nft-v2-metalswap-gear" transform="translate(0 0.000001)">'
                            '<g id="nft-v2-gears_tr" transform="translate(240.001007,162.001) rotate(0)">'
                                '<g id="nft-v2-gears" transform="translate(-240.001007,-162.000999)">'
                                    '<path id="nft-v2-bottom-gear" d="M311.11,163.503h-.244l-11.652-.203c-.772,32.032-27.001,57.78-59.24,57.78-7.024,0-13.723-1.217-19.976-3.447l-5.603,20.396c2.111.729,4.263,1.338,6.415,1.905c2.72.69,5.481,1.217,8.283,1.622l2.273-9.123c2.761.324,5.563.527,8.405.527c1.584,0,3.127-.04,4.67-.122l1.705,9.164c2.801-.203,5.603-.567,8.364-1.095c2.761-.527,5.522-1.175,8.202-1.946l-1.706-9.123c4.182-1.298,8.202-2.96,12.019-4.947l5.238,7.623c2.436-1.338,4.872-2.838,7.146-4.42c2.314-1.581,4.588-3.365,6.74-5.19l-5.238-7.582c3.248-2.879,6.253-6.001,8.933-9.407l7.795,4.744c1.706-2.23,3.289-4.541,4.751-6.974c1.461-2.392,2.801-4.866,3.979-7.42l-7.796-4.704c1.787-3.933,3.248-8.028,4.345-12.285l8.973,1.094c.649-2.757,1.137-5.514,1.502-8.312s.528-5.595.609-8.393l-8.892-.162Z" fill="#cce6f5"/>'
                                    '<path id="nft-v2-top-gear" d="M240.028,102.679c6.983,0,13.683,1.217,19.895,3.406l7.106-19.7059c-2.64-.9326-5.36-1.7435-8.08-2.4328-2.721-.6488-5.563-1.1759-8.324-1.5814l-2.192,9.1232c-2.761-.3244-5.563-.4866-8.405-.4866-1.584,0-3.127.0406-4.67.1622l-1.705-8.8393L233.572,82c-2.802.2433-5.603.6082-8.364,1.1353s-5.522,1.1759-8.202,1.9869l1.746,9.1231c-4.182,1.2976-8.202,3.0006-12.018,4.9874l-5.279-7.5824c-2.436,1.3381-4.872,2.8789-7.146,4.4602-2.314,1.6219-4.547,3.3249-6.659,5.1905l5.238,7.541c-3.248,2.879-6.212,6.042-8.892,9.448l-7.836-4.703c-1.705,2.23-3.289,4.581-4.71,6.974-1.462,2.392-2.761,4.906-3.979,7.46l7.796,4.663c-1.787,3.934-3.249,8.029-4.264,12.327l-8.973-1.054c-.609,2.757-1.096,5.514-1.462,8.312-.324,2.635-.487,5.271-.568,7.906l20.789.771c.487-32.276,26.797-58.267,59.239-58.267Z" fill="#cce6f5"/>'
                                '</g>'
                            '</g>'
                            '<path id="nft-v2-center" d="M228.135,158.24l-4.995,23.477-9.054,2.109l4.903-22.913-19.428-4.551-3.33-.851-1.989-.487-2.355-.567c3.573-23.315,23.793-41.197,48.155-41.197c13.764,0,26.148,5.677,34.999,14.8l5.644-4.501-.853,4.744.041-.04-2.883,16.219c-1.705-3.568-3.898-6.893-6.537-9.813l-.447-.486c-7.471-8.029-18.149-13.097-30.005-13.097-18.068,0-33.416,11.759-38.776,28.018l19.321,4.528l3.691-17.247h4.71l10.881,31.952l10.638-31.952h4.669l5.782,26.7l19.594,4.513l7.755,1.866-.284,1.216c-.325,1.622-.691,3.203-1.137,4.785l-.284,1.257c-6.252,19.665-24.809,33.897-46.572,33.897-13.723-.04-26.107-5.717-34.958-14.84l-5.644,4.501.04-.243-.04.04l3.654-21.125c6.496,13.989,20.626,23.68,37.07,23.68c17.947,0,33.213-11.637,38.654-27.735l-16.108-3.775l2.751,12.704-9.095-2.149-4.751-23.437-8.201,21.247h-7.025l-8.201-21.247Z" fill="#cce6f5"/>'
                        '</g>'
                    '</g>',
                        
                    NFTGeneratorSupport.metalSwapTitle,
                    
                    '<g id="nft-v2-p_to" transform="translate(320.732498,47.460199)">'
                    '<path id="nft-v2-p" d="M325.048,38.1634c-1.087-.59-2.403-.885-3.948-.885h-8.034v20.3636h4.306v-6.6022h3.619c1.565,0,2.897-.2884,3.997-.8651c1.107-.5767,1.952-1.3821,2.536-2.4162.583-1.0341.875-2.2272.875-3.5795s-.289-2.5455-.865-3.5796c-.57-1.0407-1.399-1.8527-2.486-2.436Zm-2.705,3.0625c-.543-.2851-1.233-.4276-2.068-.4276h-2.903v6.7912h2.923c.829,0,1.511-.1425,2.048-.4276.544-.2916.948-.6927,1.213-1.2031.272-.517.408-1.1103.408-1.7798c0-.6762-.136-1.2661-.408-1.7699-.265-.5104-.669-.9048-1.213-1.1832Z" transform="translate(-320.732498,-47.460199)" clip-rule="evenodd" fill="#cce6f5" fill-rule="evenodd"/>''</g>''</g>''<g id="nft-v2-clip-group" clip-path="url(#nft-v2-clipping-paths)">',
                    NFTGeneratorSupport.lightWaves,
                    '</g>',
                    
                    NFTGeneratorSupport.buildBorder(nftParamGenerate.rarityBorder),
                    
                    '<path id="nft-v2-angle" d="M380,0h75c13.807,0,25,11.1929,25,25v75L380,0Z" fill="#232a3a"/>',
                    
                    nftParamGenerate.rarityGem,
            '</svg>'
            )));

            string memory image = Base64.encode(bytes(SVGImage));
            return image;
    }

 
}