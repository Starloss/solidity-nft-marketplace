/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NFTsMarketplace is OwnableUpgradeable {

    /// VARIABLES
    uint adminFee = 1;

    /// STATES

    /// MODIFIERS

    /// FUNCTIONS
    /**
     *  @notice Constructor function that initialice the contract
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    function setAdminFee(uint _adminFee) public onlyOwner {
        require(_adminFee >= 0 && _adminFee <= 100, "Wrong fee!");

        adminFee = _adminFee;
    }
}