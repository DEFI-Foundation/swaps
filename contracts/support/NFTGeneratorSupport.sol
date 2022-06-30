// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >= 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

library NFTGeneratorSupport {

    string internal constant gearAnimationStyle = 
        '#nft-v2-gears_tr {animation: nft-v2-gears_tr__tr 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-gears_tr__tr { 0% {transform: translate(240.001007px,162.001px) rotate(0deg)} 25% {transform: translate(240.001007px,162.001px) rotate(180deg)} 50% {transform: translate(240.001007px,162.001px) rotate(180deg)} 75% {transform: translate(240.001007px,162.001px) rotate(0deg)} 100% {transform: translate(240.001007px,162.001px) rotate(0deg)}}'
    ;

    string internal constant wavesAnimationStyle =
        '#nft-v2-light-waves_to {animation: nft-v2-light-waves_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-light-waves_to__to { 0% {transform: translate(-484.877891px,145.961182px)} 100% {transform: translate(965.877892px,145.961182px)}}'
    ;

    string  internal  constant metalSwapTitleAnimationStyle =
        '#nft-v2-m_to {animation: nft-v2-m_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-m_to__to { 0% {transform: translate(162.037003px,47.460199px)} 2.5% {transform: translate(162.037003px,42.461798px)} 70% {transform: translate(162.037003px,42.461798px)} 72.5% {transform: translate(162.037003px,47.460199px)} 100% {transform: translate(162.037003px,47.460199px)}}'
        '#nft-v2-e_to {animation: nft-v2-e_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-e_to__to { 0% {transform: translate(183.501503px,47.460199px)} 2.5% {transform: translate(183.501503px,47.460199px)} 5% {transform: translate(183.501503px,52.461798px)} 67.5% {transform: translate(183.501503px,52.461798px)} 70% {transform: translate(183.501503px,47.460199px)} 100% {transform: translate(183.501503px,47.460199px)}}'
        '#nft-v2-t_to {animation: nft-v2-t_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-t_to__to { 0% {transform: translate(201.352005px,47.460199px)} 5% {transform: translate(201.352005px,47.460199px)} 7.5% {transform: translate(201.352005px,42.461798px)} 65% {transform: translate(201.352005px,42.461798px)} 67.5% {transform: translate(201.352005px,47.460199px)} 100% {transform: translate(201.352005px,47.460199px)}}'
        '#nft-v2-a_to {animation: nft-v2-a_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-a_to__to { 0% {transform: translate(218.676003px,47.460199px)} 7.5% {transform: translate(218.676003px,47.460199px)} 10% {transform: translate(218.676004px,52.461798px)} 62.5% {transform: translate(218.676004px,52.461798px)} 65% {transform: translate(218.676003px,47.460199px)} 100% {transform: translate(218.676003px,47.460199px)}}'
        '#nft-v2-l_to {animation: nft-v2-l_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-l_to__to { 0% {transform: translate(237.443497px,47.460199px)} 10% {transform: translate(237.443497px,47.460199px)} 12.5% {transform: translate(237.443497px,44.218091px)} 60% {transform: translate(237.443497px,44.218091px)} 62.5% {transform: translate(237.443497px,47.460199px)} 100% {transform: translate(237.443497px,47.460199px)}}'
        '#nft-v2-s_to {animation: nft-v2-s_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-s_to__to { 0% {transform: translate(254.210007px,47.745199px)} 12.5% {transform: translate(254.210007px,47.745199px)} 15% {transform: translate(254.210007px,52.745199px)} 57.5% {transform: translate(254.210007px,52.745199px)} 60% {transform: translate(254.210007px,47.745199px)} 100% {transform: translate(254.210007px,47.745199px)}}'
        '#nft-v2-w_to {animation: nft-v2-w_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-w_to__to { 0% {transform: translate(277.892502px,47.460199px)} 15% {transform: translate(277.892502px,47.460199px)} 17.5% {transform: translate(277.892502px,42.461798px)} 55% {transform: translate(277.892502px,42.461798px)} 57.5% {transform: translate(277.892502px,47.460199px)} 100% {transform: translate(277.892502px,47.460199px)}}'
        '#nft-v2-a2_to {animation: nft-v2-a2_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-a2_to__to { 0% {transform: translate(300.815994px,47.460199px)} 17.5% {transform: translate(300.815994px,47.460199px)} 20% {transform: translate(300.815997px,52.461798px)} 52.5% {transform: translate(300.815997px,52.461798px)} 55% {transform: translate(300.815994px,47.460199px)} 100% {transform: translate(300.815994px,47.460199px)}}'
        '#nft-v2-p_to {animation: nft-v2-p_to__to 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-p_to__to { 0% {transform: translate(320.732498px,47.460199px)} 20% {transform: translate(320.732498px,47.460199px)} 22.5% {transform: translate(320.732499px,44.441027px)} 50% {transform: translate(320.732499px,44.441027px)} 52.5% {transform: translate(320.732498px,47.460199px)} 100% {transform: translate(320.732498px,47.460199px)}}';


    string internal constant symbolDiamond =
        '<g style="transform: translate(430px, 15px)">'
            '<svg width="40" height="32" viewBox="0 0 40 32" fill="none" xmlns="http://www.w3.org/2000/svg">'
                '<path d="M17.3563 0.964711L18.191 6.48756e-05H9.06601L0 10.3816H9.20111L17.3563 0.964711ZM11.3855 10.3824H28.6195L23.9342 4.97019L20.0035 0.430102L14.0633 7.28927L11.3855 10.3824ZM0.110261 12.027L17.244 29.933L9.05039 12.027H0.110261ZM29.1385 12.0257H27.6453L21.3673 12.027H10.8664L19.9488 31.8736L20.0071 32L28.6607 13.0736L29.1385 12.0257ZM22.7817 29.9076L39.8884 12.0277H30.956L22.7817 29.9076ZM40 10.3816L30.9311 0H21.8125L30.8017 10.3816H40Z" fill="url(#paint0_linear_3103_1777)"/>'
                '<defs>'
                    '<linearGradient id="paint0_linear_3103_1777" x1="5.5" y1="3" x2="33.5" y2="24" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#CBECF7"/>'
                        '<stop offset="1" stop-color="#C9B6FF"/>'
                    '</linearGradient>'
                '</defs>'
            '</svg>'
        '</g>'
    ;

    string internal constant symbolEmerald =
        '<g style="transform: translate(436px, 15px)">'
           ' <svg width="26" height="33" viewBox="0 0 26 33" fill="none" xmlns="http://www.w3.org/2000/svg">'
                '<path d="M12.9984 8.42383L7.78516 11.9335V20.848L12.9984 24.2173L18.2775 20.848V11.9335L12.9984 8.42383Z" fill="url(#paint0_linear_3104_2182)"/>'
                '<path d="M14.3184 6.80874V0L24.8107 6.03661L18.6077 9.61646L14.3184 6.80874Z" fill="url(#paint1_linear_3104_2182)"/>'
                '<path d="M26 8.49361L19.9289 11.8629V20.8476L26 24.3573V8.49361Z" fill="url(#paint2_linear_3104_2182)"/>'
                '<path d="M24.4822 26.4631L18.6751 23.164L14.3858 25.9015V32.4997L24.4822 26.4631Z" fill="url(#paint3_linear_3104_2182)"/>'
                '<path d="M11.8122 25.9015L7.45685 23.164L1.64975 26.4631L11.8122 32.4997V25.9015Z" fill="url(#paint4_linear_3104_2182)"/>'
                '<path d="M6.13706 20.8476L0 24.3573L0.19797 8.49361L6.13706 11.8629V20.8476Z" fill="url(#paint5_linear_3104_2182)"/>'
                '<path d="M11.7462 0.140625L1.3198 6.03685L7.45685 9.6167L11.7462 6.94936V0.140625Z" fill="url(#paint6_linear_3104_2182)"/>'
                '<defs>'
                    '<linearGradient id="paint0_linear_3104_2182" x1="9.22786" y1="9.90446" x2="19.1305" y2="13.8517" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#A4F89D"/>'
                        '<stop offset="1" stop-color="#0CB41D"/>'
                    '</linearGradient>'
                    '<linearGradient id="paint1_linear_3104_2182" x1="15.7611" y1="0.901543" x2="23.7943" y2="6.16052" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#A4F89D"/>'
                        '<stop offset="1" stop-color="#0CB41D"/>'
                    '</linearGradient>'
                    '<linearGradient id="paint2_linear_3104_2182" x1="3.575" y1="3.17429" x2="26.6497" y2="14.2984" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#A4F89D"/>'
                        '<stop offset="1" stop-color="#0CB41D"/>'
                    '</linearGradient>'
                    '<linearGradient id="paint3_linear_3104_2182" x1="3.575" y1="3.17429" x2="26.6497" y2="14.2984" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#A4F89D"/>'
                        '<stop offset="1" stop-color="#0CB41D"/>'
                    '</linearGradient>'
                    '<linearGradient id="paint4_linear_3104_2182" x1="3.575" y1="3.17429" x2="26.6497" y2="14.2984" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#A4F89D"/>'
                        '<stop offset="1" stop-color="#0CB41D"/>'
                    '</linearGradient>'
                    '<linearGradient id="paint5_linear_3104_2182" x1="3.575" y1="3.17429" x2="26.6497" y2="14.2984" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#A4F89D"/>'
                        '<stop offset="1" stop-color="#0CB41D"/>'
                    '</linearGradient>'
                    '<linearGradient id="paint6_linear_3104_2182" x1="3.575" y1="3.17429" x2="26.6497" y2="14.2984" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#A4F89D"/>'
                        '<stop offset="1" stop-color="#0CB41D"/>'
                    '</linearGradient>'
                '</defs>'
            '</svg>'
        '</g>'
    ;

    string internal constant symbolAmethyst = 
        '<g style="transform: translate(436px, 15px)">'
            '<path d="M11.5361 14.0525L2.13672 13.2578L6.37179 31.2142L15.8107 32.1768L11.5361 14.0525Z" fill="url(#paint0_linear_3104_2177)"/>'
            '<path d="M19.8857 8.89468L13.0068 13.5287L17.3607 31.9885L24.1208 26.8511L19.8857 8.89468Z" fill="url(#paint1_linear_3104_2177)"/>'
            '<path d="M17.436 33.5777L6.80469 32.3506L18.9636 40.0546L24.4391 28.1915L17.436 33.5777Z" fill="url(#paint2_linear_3104_2177)"/>'
            '<path d="M12.01 13.0552L1.89985 12.251L9.39775 1.97931L19.3528 8.13469L12.01 13.0552Z" fill="url(#paint3_linear_3104_2177)"/>'
            '<defs>'
                '<linearGradient id="paint0_linear_3104_2177" x1="3.80044" y1="14.9414" x2="13.3142" y2="15.0649" gradientUnits="userSpaceOnUse">'
                    '<stop stop-color="#F557D3"/>'
                    '<stop offset="0.9999" stop-color="#7F37DB"/>'
                '</linearGradient>'
                '<linearGradient id="paint1_linear_3104_2177" x1="13.8436" y1="12.429" x2="22.1424" y2="12.2452" gradientUnits="userSpaceOnUse">'
                    '<stop stop-color="#F557D3"/>'
                    '<stop offset="0.9999" stop-color="#7F37DB"/>'
                '</linearGradient>'
                '<linearGradient id="paint2_linear_3104_2177" x1="9.45085" y1="32.7176" x2="20.8361" y2="40.1972" gradientUnits="userSpaceOnUse">'
                    '<stop stop-color="#F557D3"/>'
                    '<stop offset="0.9999" stop-color="#7F37DB"/>'
                '</linearGradient>'
                '<linearGradient id="paint3_linear_3104_2177" x1="2.64468" y1="4.66817" x2="14.9716" y2="11.8205" gradientUnits="userSpaceOnUse">'
                    '<stop stop-color="#F557D3"/>'
                    '<stop offset="0.9999" stop-color="#7F37DB"/>'
                '</linearGradient>'
            '</defs>'
        '</g>'
    ;
    
    string internal constant symbolIngot = 
        '<g style="transform: translate(430px, 16px)">'
            '<svg width="36" height="25" viewBox="0 0 36 25" fill="none" xmlns="http://www.w3.org/2000/svg">'
                '<path d="M11.6943 17.2897L2.52229 12.2664L0 18.9252L11.2357 25L11.6943 17.2897Z" fill="url(#paint0_linear_3103_1776)"/>'
                '<path d="M33.5924 6.30841L13.1847 17.2897L12.8408 25L36 12.2664L33.5924 6.30841Z" fill="url(#paint1_linear_3103_1776)"/>'
                '<path d="M12.6115 15.8879L3.55414 10.9813L23.6178 0L32.9045 5.02336L12.6115 15.8879Z" fill="url(#paint2_linear_3103_1776)"/>'
                '<defs>'
                    '<linearGradient id="paint0_linear_3103_1776" x1="4.95" y1="2.34375" x2="27.4951" y2="21.8228" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F4F1AA"/>'
                        '<stop offset="1" stop-color="#E9BF6E"/>'
                    '</linearGradient>'
                    '<linearGradient id="paint1_linear_3103_1776" x1="4.95" y1="2.34375" x2="27.4951" y2="21.8228" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F4F1AA"/>'
                        '<stop offset="1" stop-color="#E9BF6E"/>'
                    '</linearGradient>'
                    '<linearGradient id="paint2_linear_3103_1776" x1="4.95" y1="2.34375" x2="27.4951" y2="21.8228" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F4F1AA"/>'
                        '<stop offset="1" stop-color="#E9BF6E"/>'
                    '</linearGradient>'
                '</defs>'
            '</svg>'
        '</g>'
    ;


    string internal constant metalSwapTitle =
        '<g id="nft-v2-m_to" transform="translate(162.037003,47.460199)">'
            '<path id="nft-v2-m" d="M160.615,57.5426l-5.27-13.2045h-.169v13.3039h-4.176v-20.3636h5.31l5.608,13.6818h.238l5.608-13.6818h5.31v20.3636h-4.176v-13.2542h-.169l-5.27,13.1548h-2.844Z" transform="translate(-162.037003,-47.460199)" fill="#cce6f5"/>'
        '</g>'

        '<g id="nft-v2-e_to" transform="translate(183.501503,47.460199)">'
            '<path id="nft-v2-e" d="M176.621,57.642v-20.3636h13.722v3.5497h-9.417v4.8523h8.711v3.5497h-8.711v4.8622h9.456v3.5497h-13.761Z" transform="translate(-183.501503,-47.460199)" fill="#cce6f5"/>'
        '</g>'

        '<g id="nft-v2-t_to" transform="translate(201.352005,47.460199)">'
            '<path id="nft-v2-t" d="M192.99,37.2784v3.5497h6.234v16.8139h4.256v-16.8139h6.234v-3.5497h-16.724Z" transform="translate(-201.352005,-47.460199)" fill="#cce6f5"/>'
        '</g>'

        '<g id="nft-v2-a_to" transform="translate(218.676003,47.460199)">'
            '<path id="nft-v2-a" d="M215.001,52.9986L213.49,57.642h-4.613l7.03-20.3636h5.548l7.02,20.3636h-4.614l-1.508-4.6434h-7.352Zm3.759-11.0668l2.502,7.706h-5.168l2.507-7.706h.159Z" transform="translate(-218.676003,-47.460199)" clip-rule="evenodd" fill="#cce6f5" fill-rule="evenodd"/>'
        '</g>'

        '<g id="nft-v2-l_to" transform="translate(237.443497,47.460199)">'
            '<path id="nft-v2-l" d="M230.926,37.2784v20.3636h13.035v-3.5497h-8.73v-16.8139h-4.305Z" transform="translate(-237.443497,-47.460199)" fill="#cce6f5"/>'
        '</g>'

        '<g id="nft-v2-s_to" transform="translate(254.210007,47.745199)">'
            '<path id="nft-v2-s" d="M257.859,43.1349c-.079-.802-.421-1.4251-1.024-1.8693-.603-.4441-1.422-.6662-2.456-.6662-.702,0-1.296.0995-1.78.2983-.483.1923-.855.4607-1.113.8054-.252.3447-.378.7358-.378,1.1733-.013.3646.063.6828.229.9546.172.2717.407.5071.706.7059.298.1923.643.3613,1.034.5071.391.1392.808.2586,1.253.358l1.829.4375c.888.1989,1.704.464,2.446.7954.743.3315,1.386.7392,1.929,1.2231.544.4839.965,1.0539,1.263,1.7102.305.6562.461,1.4086.467,2.2571-.006,1.2462-.325,2.3267-.954,3.2415-.623.9081-1.525,1.6141-2.705,2.1179-1.173.4971-2.588.7457-4.246.7457-1.644,0-3.075-.2519-4.295-.7557-1.213-.5038-2.161-1.2495-2.844-2.2372-.676-.9943-1.031-2.224-1.064-3.6889h4.166c.047.6827.242,1.2528.587,1.7102.351.4508.819.7921,1.402,1.0242.59.2253,1.256.338,1.999.338.729,0,1.362-.106,1.899-.3182.543-.2121.964-.5071,1.263-.8849.298-.3778.447-.812.447-1.3026c0-.4573-.136-.8418-.408-1.1534-.265-.3115-.656-.5767-1.173-.7954-.51-.2188-1.137-.4176-1.879-.5966l-2.218-.5568c-1.716-.4176-3.072-1.0706-4.066-1.9588-.995-.8883-1.488-2.0848-1.482-3.5895-.006-1.233.322-2.3102.985-3.2316.669-.9214,1.587-1.6406,2.754-2.1576c1.166-.5171,2.492-.7756,3.977-.7756c1.511,0,2.831.2585,3.957.7756c1.134.517,2.016,1.2362,2.645,2.1576.63.9214.955,1.9887.975,3.2017h-4.127Z" transform="translate(-254.210007,-47.4652)" fill="#cce6f5"/>''</g>''<g id="nft-v2-w_to" transform="translate(277.892502,47.460199)">''<path id="nft-v2-w" d="M263.917,37.2784l5.827,20.3636h4.196l3.868-13.3139h.159l3.878,13.3139h4.196l5.827-20.3636h-4.704l-3.37,14.179h-.179l-3.709-14.179h-4.027L272.16,51.4276h-.169L268.62,37.2784h-4.703Z" transform="translate(-277.892502,-47.460199)" fill="#cce6f5"/>''</g>''<g id="nft-v2-a2_to" transform="translate(300.815994,47.460199)">''<path id="nft-v2-a2" d="M297.142,52.9986l-1.511,4.6434h-4.614l7.03-20.3636h5.549l7.019,20.3636h-4.613l-1.508-4.6434h-7.352Zm3.759-11.0668l2.502,7.706h-5.168l2.507-7.706h.159Z" transform="translate(-300.815994,-47.460199)" clip-rule="evenodd" fill="#cce6f5" fill-rule="evenodd"/>'
        '</g>'
    ;


    string internal constant lightWaves =
        '<g id="nft-v2-light-waves_to" transform="translate(-484.877891,145.961182)">'
            '<rect id="nft-v2-light-waves" width="427.255264" height="514.89737" rx="0" ry="0"   transform="scale(2.274415,0.934757) translate(-213.627632,-257.448685)" opacity="0.25" fill="url(#nft-v2-light-waves-fill)" stroke-width="0"/>'
        '</g>'
        '<clipPath id="nft-v2-clipping-paths">'
            '<path id="nft-v2-base3" d="M0,10C0,4.47715,4.47715,0,10,0h445c13.807,0,25,11.1929,25,25v245c0,5.523-4.477,10-10,10h-460.00001C4.47714,280,0,275.523,0,270L0,10Z" fill="#cce6f5"/>'
        '</clipPath>'
    ;

    string internal constant sparkleBackground =
        '<g id="nft-v2-star1" opacity="0">'
            '<polygon id="nft-v2-star12" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(345.321327 107.651327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star13" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(153.651328 110.151327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star14" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(46.151327 110.151327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star15" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(69.13097 41.696473)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star16" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(411.973827 220.30233)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star17" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(61.151327 250.776327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star18" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(153.651328 205.770329)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star19" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(200.533328 254.651327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star110" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(345.321327 107.651327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star111" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(446.368327 154.632155)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star112" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(370.305327 47.429728)" fill="#fff" stroke-width="0"/>'
        '</g>'
        '<g id="nft-v2-star2" transform="translate(.000001 0)" opacity="0">'
            '<polygon id="nft-v2-star22" points="-3.70709,-11.20709 -2.116099,-5.298081 3.79291,-3.70709 -2.116099,-2.116099 -3.70709,3.79291 -5.298081,-2.116099 -11.20709,-3.70709 -5.298081,-5.298081 -3.70709,-11.20709" transform="translate(99.207091 68.849092)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star23" points="-3.70709,-11.20709 -2.116099,-5.298081 3.79291,-3.70709 -2.116099,-2.116099 -3.70709,3.79291 -5.298081,-2.116099 -11.20709,-3.70709 -5.298081,-5.298081 -3.70709,-11.20709" transform="translate(62.187472 201.826093)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star24" points="-3.70709,-11.20709 -2.116099,-5.298081 3.79291,-3.70709 -2.116099,-2.116099 -3.70709,3.79291 -5.298081,-2.116099 -11.20709,-3.70709 -5.298081,-5.298081 -3.70709,-11.20709" transform="translate(169.281092 222.707091)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star25" points="-3.70709,-11.20709 -2.116099,-5.298081 3.79291,-3.70709 -2.116099,-2.116099 -3.70709,3.79291 -5.298081,-2.116099 -11.20709,-3.70709 -5.298081,-5.298081 -3.70709,-11.20709" transform="translate(434.924091 194.326093)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star26" points="-3.70709,-11.20709 -2.116099,-5.298081 3.79291,-3.70709 -2.116099,-2.116099 -3.70709,3.79291 -5.298081,-2.116099 -11.20709,-3.70709 -5.298081,-5.298081 -3.70709,-11.20709" transform="translate(358.861091 138.187919)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star27" points="-3.70709,-11.20709 -2.116099,-5.298081 3.79291,-3.70709 -2.116099,-2.116099 -3.70709,3.79291 -5.298081,-2.116099 -11.20709,-3.70709 -5.298081,-5.298081 -3.70709,-11.20709" transform="translate(341.377091 30.707091)" fill="#fff" stroke-width="0"/>'
        '</g>'
        '<g id="nft-v2-star3" transform="matrix(1 0 0-1 32 276)">'
            '<polygon id="nft-v2-star113" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(345.321327 107.651327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star114" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(76.151328 107.651327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star115" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(68.631708 34.651327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star116" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(272.519328 29.651327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star117" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(96.315878 261.651325)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star118" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(153.651328 205.770329)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star119" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(209.126328 261.651325)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star120" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(345.321327 107.651327)" fill="#fff" stroke-width="0"/>'
            '<polygon id="nft-v2-star121" points="-12.651326,-17.651326 -11.590666,-13.711986 -7.651326,-12.651326 -11.590666,-11.590666 -12.651326,-7.651326 -13.711986,-11.590666 -17.651326,-12.651326 -13.711986,-13.711986 -12.651326,-17.651326" transform="translate(435.651327 69.651325)" fill="#fff" stroke-width="0"/>'
        '</g>'
    ;

    string internal constant sparkleBackgroundStyle =
        '#nft-v2-star1 {animation: nft-v2-star1_c_o 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-star1_c_o { 0% {opacity: 0} 25% {opacity: 1} 50% {opacity: 0} 75% {opacity: 1} 100% {opacity: 0}}'
        '#nft-v2-star2 {animation: nft-v2-star2_c_o 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-star2_c_o { 0% {opacity: 0} 18.75% {opacity: 1} 37.5% {opacity: 0} 56.25% {opacity: 1} 75% {opacity: 0} 100% {opacity: 1}}'
        '#nft-v2-star3 {animation: nft-v2-star3_c_o 8000ms linear infinite normal forwards}'
        '@keyframes nft-v2-star3_c_o { 0% {opacity: 1} 25% {opacity: 0} 50% {opacity: 1} 75% {opacity: 0} 100% {opacity: 1}}'
    ;



function generateDefinitions(string memory color1, string memory color2) internal pure returns (string memory definitionsSVG) {
        return string(abi.encodePacked(
            '<linearGradient id="nft-v2-base-light-fill" x1="0" y1="0" x2="482" y2="283" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)">'
                '<stop id="nft-v2-base-light-fill-0" offset="5.8773%" stop-color="#161616"/>'
                '<stop id="nft-v2-base-light-fill-1" offset="15.383%" stop-color="#fff"/>'
                '<stop id="nft-v2-base-light-fill-2" offset="33.5914%" stop-color="#151515"/>'
                '<stop id="nft-v2-base-light-fill-3" offset="42.8409%" stop-color="#fcfcfc"/>'
                '<stop id="nft-v2-base-light-fill-4" offset="59.573%" stop-color="#1c1c1c"/>'
                '<stop id="nft-v2-base-light-fill-5" offset="74.4792%" stop-color="#fbfbfb"/>'
                '<stop id="nft-v2-base-light-fill-6" offset="87.5308%" stop-color="#000"/>'
            '</linearGradient>'
            '<linearGradient id="nft-v2-color-fill" x1="10" y1="10" x2="462.517" y2="282.429" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)">'
                '<stop id="nft-v2-color-fill-0" offset="0.02%" stop-color="',
                color1,
                '"/>'
                '<stop id="nft-v2-color-fill-1" offset="100%" stop-color="',
                color2,
                '"/>'
            '</linearGradient>'
            '<linearGradient id="nft-v2-color-light-fill" x1="10" y1="10" x2="463.105" y2="281.507" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)">'
                '<stop id="nft-v2-color-light-fill-0" offset="0%" stop-color="#000"/>'
                '<stop id="nft-v2-color-light-fill-1" offset="15.625%" stop-color="#fff"/>'
                '<stop id="nft-v2-color-light-fill-2" offset="28.6458%" stop-color="#626262"/>'
                '<stop id="nft-v2-color-light-fill-3" offset="39.0625%" stop-color="#8a8a8a"/>'
                '<stop id="nft-v2-color-light-fill-4" offset="50%" stop-color="#6c6c6c"/>'
                '<stop id="nft-v2-color-light-fill-5" offset="57.8125%" stop-color="#8c8c8c"/>'
                '<stop id="nft-v2-color-light-fill-6" offset="68.2292%" stop-color="#fff"/>'
                '<stop id="nft-v2-color-light-fill-7" offset="78.125%" stop-color="#525252"/>'
                '<stop id="nft-v2-color-light-fill-8" offset="88.0208%" stop-color="#fffefe"/>'
                '<stop id="nft-v2-color-light-fill-9" offset="100%" stop-color="#000"/>'
            '</linearGradient>'
            '<linearGradient id="nft-v2-path3-fill" x1="38" y1="166.946" x2="107.414" y2="115.066" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)">'
                '<stop id="nft-v2-path3-fill-0" offset="0%" stop-color="#d7993e"/>'
                '<stop id="nft-v2-path3-fill-1" offset="100%" stop-color="#efe59e"/>'
            '</linearGradient>'
            '<linearGradient id="nft-v2-decotration-light-fill" x1="387.084" y1="86" x2="430.585" y2="42.8052" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)">'
                '<stop id="nft-v2-decotration-light-fill-0" offset="0%" stop-color="#656565"/>'
                '<stop id="nft-v2-decotration-light-fill-1" offset="21.875%" stop-color="#3c3c3c"/>'
                '<stop id="nft-v2-decotration-light-fill-2" offset="45.3125%" stop-color="#bababa"/>'
                '<stop id="nft-v2-decotration-light-fill-3" offset="59.8958%" stop-color="#939393"/>'
                '<stop id="nft-v2-decotration-light-fill-4" offset="73.9583%" stop-color="#e0e0e0"/>'
                '<stop id="nft-v2-decotration-light-fill-5" offset="86.7478%" stop-color="#fff"/>'
                '<stop id="nft-v2-decotration-light-fill-6" offset="100%" stop-color="#080808"/>'
            '</linearGradient>'
            '<linearGradient id="nft-v2-gems-color-fill" x1="435.5" y1="19" x2="463.5" y2="40" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)">'
                '<stop id="nft-v2-gems-color-fill-0" offset="0%" stop-color="#cbecf7"/>'
                '<stop id="nft-v2-gems-color-fill-1" offset="100%" stop-color="#c9b6ff"/>'
            '</linearGradient>'
            '<linearGradient id="nft-v2-light-waves-fill" x1="0.023146" y1="0.349648" x2="0.976854" y2="0.650352" spreadMethod="pad" gradientUnits="objectBoundingBox" gradientTransform="translate(0 0)">'
                '<stop id="nft-v2-light-waves-fill-0" offset="17%" stop-color="rgba(255,255,255,0)"/>'
                '<stop id="nft-v2-light-waves-fill-1" offset="24%" stop-color="#fff"/>'
                '<stop id="nft-v2-light-waves-fill-2" offset="31%" stop-color="rgba(255,255,255,0.49)"/>'
                '<stop id="nft-v2-light-waves-fill-3" offset="38%" stop-color="#fff"/>'
                '<stop id="nft-v2-light-waves-fill-4" offset="47%" stop-color="rgba(255,255,255,0)"/>'
                '<stop id="nft-v2-light-waves-fill-5" offset="56%" stop-color="#fff"/>'
                '<stop id="nft-v2-light-waves-fill-6" offset="65%" stop-color="rgba(255,255,255,0)"/>'
                '<stop id="nft-v2-light-waves-fill-7" offset="73%" stop-color="#fff"/>'
                '<stop id="nft-v2-light-waves-fill-8" offset="80%" stop-color="rgba(255,255,255,0)"/>'
            '</linearGradient>'
        ));
    }

    function buildBorder (string memory borderColor)  internal pure returns (string memory borderSVG)  {
        return string(abi.encodePacked(
            '<g id="nft-v2-decoration">'
                '<path id="nft-v2-decoration-shadow" d="M378.039,0c.409,16.1851-.009,27.1126-1.482,48.3-1.238,17.8048-1.023,25.2,7.168,32.55c9.219,6.3,15.253,4.297,28.678,3.15c12.289-1.05,23.556-1.05,37.894,5.25c4.648,1.3607,9.219,6.3,16.389,10.5c3.131,1.834,9.708,4.141,13.314,5.25C480,55.125,428.51,0,378.039,0Z" fill-opacity="0.25"/>'
                '<path id="nft-v2-decoration2" d="M380,0c.401,15.4144-.009,25.8215-1.454,46-1.214,16.957-1.003,24,7.031,31c9.041,6,14.959,4.0924,28.125,3c12.053-1,23.104-1,37.167,5c5.131,2.5,9.041,6,16.073,10c3.071,1.7471,9.521,3.9438,13.058,5C443.47,57.2947,422.085,35.3442,380,0Z" fill="',
                borderColor,
                '"/>'
                '<path id="nft-v2-decotration-light" style="mix-blend-mode:soft-light" d="M380,0c.401,15.4144-.009,25.8215-1.454,46-1.214,16.957-1.003,24,7.031,31c9.041,6,14.959,4.0924,28.125,3c12.053-1,23.104-1,37.167,5c5.131,2.5,9.041,6,16.073,10c3.071,1.7471,9.521,3.9438,13.058,5C443.47,57.2947,422.085,35.3442,380,0Z" fill="url(#nft-v2-decotration-light-fill)"/>'
            '</g>'
        ));
    }

    function buildTokenId (uint256 tokenId)  internal pure returns (string memory tokenIdSVG)  {
        return string(abi.encodePacked(
            '<g id="tokenText">'
                '<rect id="nft-v2-id-shadow" width="112" height="22" rx="4" ry="4" transform="translate(338 237)" fill-opacity="0.25"/>'
                '<g style="transform: translate(332px, 238px)">'
                    '<text x="12px" y="17px" fontFamily="Arial, monospace" font-size="20px" font-weight="700" fill="#CCE6F5">'
                        'ID: ',
                        Strings.toString(tokenId),
                    '</text>'
                '</g>'
            '</g>'
        ));
    }


}