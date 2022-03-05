/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract NFTsMarketplace is AccessControlUpgradeable {

    /// VARIABLES
    uint adminFee = 1;

    /**
     *  @notice Bytes32 used for roles in the Dapp
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Offer {
        address tokenAddress;
        uint tokenID;
        uint tokenAmount;
        uint deadline;
        uint price;
    }
    
    mapping(address => Offer[]) offersByAddress;

    /// STATES

    /// EVENTS
    /**
     *  @notice Event emitted when an Sell Order is created
     */
    event SellOrderCreated(
        address _seller,
        address _tokenAddress,
        uint _tokenID,
        uint _tokenAmount,
        uint _deadline,
        uint _price
    );

    /// MODIFIERS

    /// FUNCTIONS
    /**
     *  @notice Constructor function that initialice the contract
     */
    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function createNewOffer(
        address _tokenAddress,
        uint _tokenID,
        uint _tokenAmount,
        uint _deadline,
        uint _price
    ) public {
        ERC1155 token = ERC1155(_tokenAddress);

        require(token.isApprovedForAll(msg.sender, address(this)), "This contract is not allowed to transfer sender's tokens");
        require(token.balanceOf(msg.sender, _tokenID) >= _tokenAmount, "The user has not enough tokens");

        Offer memory newOffer = Offer(_tokenAddress, _tokenID, _tokenAmount, _deadline, _price);
        offersByAddress[msg.sender].push(newOffer);

        emit SellOrderCreated(msg.sender, _tokenAddress, _tokenID, _tokenAmount, _deadline, _price);
    }

    function setAdminFee(uint _adminFee) public onlyRole(ADMIN_ROLE) {
        require(_adminFee >= 0 && _adminFee <= 100, "Wrong fee!");

        adminFee = _adminFee;
    }
}