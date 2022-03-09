/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract NFTsMarketplace is AccessControlUpgradeable {

    /// VARIABLES
    /**
     *  @notice uint's used for storage
     *  adminFee is the fee for every buy transaction
     *  orderCount is the counter for every sell order created and used for the order ID
     */
    uint public adminFee;
    uint public orderCount;

    /**
     *  @notice Variables used for getting the feed prices of ETH, DAI and LINK
     */
    AggregatorV3Interface internal ETHFeed;
    AggregatorV3Interface internal DAIFeed;
    AggregatorV3Interface internal LINKFeed;

    /**
     *  @notice Variables used for getting the contract of DAI and LINK and the address for withdraw
     */
    address public DAIAddress;
    address public LINKAddress;
    address public recipientAddress;

    /**
     *  @notice Bytes32 used for roles
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     *  @notice Struct used for make orders in order
     *  @param tokenAddress is the Token's contract address in sell
     *  @param seller is the payable address of the seller
     *  @param tokenID is the ID of the token in sell
     *  @param tokenAmount is the amount of the token in sell
     *  @param deadline is the number of seconds that the order is available until the creation of the order
     *  @param price is the amount of USD asked by the seller
     *  @param ID is the ID of the order, using orderCount as variable for setting this
     *  @param state is a control variable for set the order available, done or cancelled
     */
    struct Order {
        address tokenAddress;
        address payable seller;
        uint tokenID;
        uint tokenAmount;
        uint deadline;
        uint price;
        uint ID;
        OrderState state;
    }
    
    /**
     *  @notice Mapping used for store all orders by his ID
     */
    mapping(uint => Order) public ordersByID;

    /// STATES
    /**
     *  @notice Enum used for control in the orders
     */
    enum OrderState {OPEN, DONE, CANCELED}

    /// EVENTS
    /**
     *  @notice Event emitted when an Sell Order is created
     */
    event SellOrderCreated(
        uint _orderID,
        address _seller,
        address _tokenAddress,
        uint _tokenID,
        uint _tokenAmount,
        uint _deadline,
        uint _price
    );

    /**
     *  @notice Event emitted when an Sell Order is canceled
     */
    event SellOrderCanceled(
        uint _orderID
    );

    /**
     *  @notice Event emitted when an Sell Order is completed
     */
    event SellOrderCompleted(
        uint _orderID,
        address _buyer
    );

    /// MODIFIERS
    /**
     *  @notice Modifier function that verifies if the order is available
     *  @param _orderID is the ID of the order for check
     *  Require that the order wasn't cancelled, completed, or the deadline hasn't reached
     */
    modifier orderIsAvailable(uint _orderID) {
        require(
            ordersByID[_orderID].state == OrderState.OPEN,
            "The order is not available"
        );
        require(
            ordersByID[_orderID].deadline > block.timestamp,
            "The order has reached his deadline"
        );
        _;
    }

    /**
     *  @notice Modifier function that verifies if the user can create the sell order
     *  @param token is the contract of the token for sell
     *  @param _tokenID is the ID of the token for sell
     *  @param _tokenAmount is the amount of the token for sell
     *  Require that the user has approved the use of his tokens and has enough for the sale
     */
    modifier canCreateOrder(ERC1155 token, uint _tokenID, uint _tokenAmount) {
        require(
            token.isApprovedForAll(msg.sender, address(this)),
            "This contract is not allowed to transfer sender's tokens"
        );
        require(
            token.balanceOf(msg.sender, _tokenID) >= _tokenAmount,
            "The user has not enough tokens"
        );
        _;
    }

    /**
     *  @notice Modifier function that verifies if the user is the owner of the order
     *  @param  _orderID is the ID of the order for check
     *  Require that the user is setted as seller in the order
     */
    modifier ownerOfOrder(uint _orderID) {
        require(
            msg.sender == ordersByID[_orderID].seller,
            "You are not the owner of this order"
        );
        _;
    }

    /// FUNCTIONS
    /**
     *  @notice Constructor function that initialice the contract
     *  It grants the ADMIN_ROLE role to the deployer, and set all addresses and variables
     */
    function initialize() public initializer {
        __AccessControl_init();

        _grantRole(ADMIN_ROLE, msg.sender);
        recipientAddress = msg.sender;

        adminFee = 1;
        orderCount = 0;

        setETHFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        setDAIFeed(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
        setLINKFeed(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);

        setDAIAddress(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        setLINKAddress(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    }

    /**
     *  @notice Function that allows to create a sell order after some validations
     *  @param _tokenAddress is the Token's contract address for sell
     *  @param _tokenID is the ID of the token for sell 
     *  @param _tokenAmount is the amount of the token for sell 
     *  @param _deadline is the amount of seconds which this order will be available until its creation 
     *  @param _price is the amount of USD asked by the seller 
     */
    function createNewOrder(
        address _tokenAddress,
        uint _tokenID,
        uint _tokenAmount,
        uint _deadline,
        uint _price
    )
        public
        canCreateOrder(ERC1155(_tokenAddress), _tokenID, _tokenAmount)
    {
        orderCount++;

        Order memory newOrder = Order(
            _tokenAddress,
            payable(msg.sender),
            _tokenID,
            _tokenAmount,
            _deadline + block.timestamp,
            _price,
            orderCount,
            OrderState.OPEN
        );
        ordersByID[orderCount] = newOrder;

        emit SellOrderCreated(
            orderCount,
            msg.sender,
            _tokenAddress,
            _tokenID,
            _tokenAmount,
            _deadline + block.timestamp,
            _price
        );
    }

    /**
     *  @notice Function that allows to cancel a sell order after some validations
     *  @param _orderID is the ID of the order to be cancelled
     */
    function cancelOrder(uint _orderID)
        public
        orderIsAvailable(_orderID)
        ownerOfOrder(_orderID)
    {
        ordersByID[_orderID].state = OrderState.CANCELED;

        emit SellOrderCanceled(_orderID);
    }

    /**
     *  @notice Function that allows an user to buy a token in a order sell with ETH
     *  @param _orderID is the ID of the order to be buyed
     *  Require that the order are available, that have sended enough ETH, that the seller hasn't revoked
     *  the access of his tokens to this contract and that the seller have enough tokens
     */
    function buyWithETH(uint _orderID) payable public orderIsAvailable(_orderID) {
        uint weiCost = (ordersByID[_orderID].price * 10 ** 36) / uint(getETHPrice() * 10 ** 10);

        require(msg.value >= weiCost, "Not enough ETH sended for this transaction");

        ERC1155 token = ERC1155(ordersByID[_orderID].tokenAddress);

        require(
            token.isApprovedForAll(ordersByID[_orderID].seller, address(this)),
            "The seller has revoked access to their tokens to this contract"
        );

        require(
            token.balanceOf(
                ordersByID[_orderID].seller,
                ordersByID[_orderID].tokenID
            ) >= ordersByID[_orderID].tokenAmount,
            "The seller doesn't have enough tokens"
        );

        (bool success, ) = msg.sender.call{value: msg.value - weiCost}("");
        require(success);

        ordersByID[_orderID].state = OrderState.DONE;

        (success, ) = ordersByID[_orderID].seller.call{value: (weiCost * (100 - adminFee)) / 100}("");
        require(success);

        token.safeTransferFrom(
            ordersByID[_orderID].seller,
            msg.sender,
            ordersByID[_orderID].tokenID,
            ordersByID[_orderID].tokenAmount,
            ""
        );

        emit SellOrderCompleted(_orderID, msg.sender);
    }

    /**
     *  @notice Function that allows an user to buy a token in a order sell with DAI
     *  @param _orderID is the ID of the order to be buyed
     *  Require that the order are available, that the seller hasn't revoked the access of his tokens
     *  to this contract, that the seller have enough tokens, that the buyer has enough tokens and
     *  that this contract is allowed to spend equal or more tokens of the buyer for this tx
     */
    function buyWithDAI(uint _orderID) public orderIsAvailable(_orderID) {
        uint DAICost = (ordersByID[_orderID].price * 10 ** 36) / uint(getDAIPrice() * 10 ** 10);

        ERC1155 token = ERC1155(ordersByID[_orderID].tokenAddress);

        require(
            token.isApprovedForAll(ordersByID[_orderID].seller, address(this)),
            "The seller has revoked access to their tokens to this contract"
        );

        require(
            token.balanceOf(
                ordersByID[_orderID].seller,
                ordersByID[_orderID].tokenID
            ) >= ordersByID[_orderID].tokenAmount,
            "The seller doesn't have enough tokens"
        );

        ERC20 coin = ERC20(DAIAddress);

        require(
            coin.allowance(msg.sender, address(this)) >= DAICost,
            "This contract is not allowed to transfer buyer's tokens"
        );

        ordersByID[_orderID].state = OrderState.DONE;

        require(
            coin.transferFrom(
                msg.sender,
                address(this),
                (DAICost * adminFee) / 100
            )
        );
        require(
            coin.transferFrom(
                msg.sender,
                ordersByID[_orderID].seller,
                (DAICost * (100 - adminFee)) / 100
            )
        );

        token.safeTransferFrom(
            ordersByID[_orderID].seller,
            msg.sender,
            ordersByID[_orderID].tokenID,
            ordersByID[_orderID].tokenAmount,
            ""
        );

        emit SellOrderCompleted(_orderID, msg.sender);
    }

    /**
     *  @notice Function that allows an user to buy a token in a order sell with LINK
     *  @param _orderID is the ID of the order to be buyed
     *  Require that the order are available, that the seller hasn't revoked the access of his tokens
     *  to this contract, that the seller have enough tokens, that the buyer has enough tokens and
     *  that this contract is allowed to spend equal or more tokens of the buyer for this tx
     */
    function buyWithLINK(uint _orderID) public orderIsAvailable(_orderID) {
        uint LINKCost = (ordersByID[_orderID].price * 10 ** 36) / uint(getLINKPrice() * 10 ** 10);

        ERC1155 token = ERC1155(ordersByID[_orderID].tokenAddress);

        require(
            token.isApprovedForAll(ordersByID[_orderID].seller, address(this)),
            "The seller has revoked access to their tokens to this contract"
        );

        require(
            token.balanceOf(
                ordersByID[_orderID].seller,
                ordersByID[_orderID].tokenID
            ) >= ordersByID[_orderID].tokenAmount,
            "The seller doesn't have enough tokens"
        );

        ERC20 coin = ERC20(LINKAddress);

        require(
            coin.allowance(msg.sender, address(this)) >= LINKCost,
            "This contract is not allowed to transfer buyer's tokens"
        );

        ordersByID[_orderID].state = OrderState.DONE;

        require(
            coin.transferFrom(
                msg.sender,
                address(this),
                (LINKCost * adminFee) / 100
            )
        );
        require(
            coin.transferFrom(
                msg.sender,
                ordersByID[_orderID].seller,
                (LINKCost * (100 - adminFee)) / 100
            )
        );

        token.safeTransferFrom(
            ordersByID[_orderID].seller,
            msg.sender,
            ordersByID[_orderID].tokenID,
            ordersByID[_orderID].tokenAmount,
            ""
        );

        emit SellOrderCompleted(_orderID, msg.sender);
    }

    /**
     *  @notice Set function that allows the admin to set the ETH feed address
     *  @param _address is an address which will be the new ETH feed address
     */
    function setETHFeed(address _address) public onlyRole(ADMIN_ROLE) {
        ETHFeed = AggregatorV3Interface(_address);
    }

    /**
     *  @notice Set function that allows the admin to set the DAI feed address
     *  @param _address is an address which will be the new DAI feed address
     */
    function setDAIFeed(address _address) public onlyRole(ADMIN_ROLE) {
        DAIFeed = AggregatorV3Interface(_address);
    }

    /**
     *  @notice Set function that allows the admin to set the LINK feed address
     *  @param _address is an address which will be the new LINK feed address
     */
    function setLINKFeed(address _address) public onlyRole(ADMIN_ROLE) {
        LINKFeed = AggregatorV3Interface(_address);
    }

    /**
     *  @notice Set function that allows the admin to set the DAI contract address
     *  @param _address is an address which will be the new DAI contract address
     */
    function setDAIAddress(address _address) public onlyRole(ADMIN_ROLE) {
        DAIAddress = _address;
    }

    /**
     *  @notice Set function that allows the admin to set the LINK contract address
     *  @param _address is an address which will be the new LINK contract address
     */
    function setLINKAddress(address _address) public onlyRole(ADMIN_ROLE) {
        LINKAddress = _address;
    }

    /**
     *  @notice Set function that allows the admin to set the admin fee
     *  @param _adminFee is a uint which will be the new admin fee
     */
    function setAdminFee(uint _adminFee) external onlyRole(ADMIN_ROLE) {
        require(_adminFee >= 0 && _adminFee <= 10, "Wrong fee!");

        adminFee = _adminFee;
    }

    /**
     *  @notice Set function that allows the admin to set the admin fee
     *  @param _recipientAddress is the address which will be the new recipient address
     */
    function setRecipientAddress(address _recipientAddress) external onlyRole(ADMIN_ROLE) {
        recipientAddress = _recipientAddress;
    }

    /**
     *  @notice Function that allow the admin to withdraw all the funds
     */
    function withdraw() public onlyRole(ADMIN_ROLE) {
        (bool success, ) = recipientAddress.call{value: address(this).balance}("");
        require(success);
    }

    /**
     *  @notice Function that allow to know if an address has the ADMIN_ROLE role
     *  @param _address is the address for check
     *  @return a boolean, true if the user has the ADMIN_ROLE role or false otherwise
     */
    function isAdmin(address _address) external view returns (bool) {
        return(hasRole(ADMIN_ROLE, _address));
    }

    /**
     *  @notice Function that gets the price of ETH in USD using Chainlink
     *  @return an int with the price of ETH in USD with 10 decimals
     */
    function getETHPrice() internal view returns (int) {
        ( , int price, , , ) = ETHFeed.latestRoundData();
        return price;
    }

    /**
     *  @notice Function that gets the price of DAI in USD using Chainlink
     *  @return an int with the price of DAI in USD with 10 decimals
     */
    function getDAIPrice() internal view returns (int) {
        ( , int price, , , ) = DAIFeed.latestRoundData();
        return price;
    }

    /**
     *  @notice Function that gets the price of LINK in USD using Chainlink
     *  @return an int with the price of LINK in USD with 10 decimals
     */
    function getLINKPrice() internal view returns (int) {
        ( , int price, , , ) = LINKFeed.latestRoundData();
        return price;
    }
}