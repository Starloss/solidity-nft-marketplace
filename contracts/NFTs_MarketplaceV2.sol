/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./NFTs_Marketplace.sol";

contract NFTsMarketplaceV2 is NFTsMarketplace {
    function upgradeTest(uint _data) public pure returns (uint) {
        return _data + 2;
    }
}