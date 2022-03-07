/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract NFTsMarketplace is AccessControlUpgradeable, ReentrancyGuardUpgradeable {

    /// VARIABLES
    uint adminFee = 1;
    uint orderCount = 0;

    AggregatorV3Interface internal ETHFeed;
    AggregatorV3Interface internal DAIFeed;
    AggregatorV3Interface internal LINKFeed;

    address DAIAddress;
    address LINKAddress;

    /**
     *  @notice Bytes32 used for roles in the Dapp
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Order {
        address tokenAddress;
        address payable seller;
        uint tokenID;
        uint tokenAmount;
        uint deadline;
        uint price;
        uint orderID;
        OrderState state;
    }
    
    mapping(uint => Order) ordersByID;

    /// STATES

    enum OrderState {OPEN, DONE, CANCELED, ERROR_APPROVED, ERROR_AMOUNT, TIME_ENDED}

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

    event SellOrderCanceled(
        uint _orderID
    );

    event SellOrderCompleted(
        uint _orderID,
        address _buyer
    );

    /// MODIFIERS

    /// FUNCTIONS
    /**
     *  @notice Constructor function that initialice the contract
     */
    function initialize() public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(ADMIN_ROLE, msg.sender);

        ETHFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        DAIFeed = AggregatorV3Interface(0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF);
        LINKFeed = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);
    }

    function createNewOrder(
        address _tokenAddress,
        uint _tokenID,
        uint _tokenAmount,
        uint _deadline,
        uint _price
    ) public {
        ERC1155 token = ERC1155(_tokenAddress);

        require(token.isApprovedForAll(msg.sender, address(this)), "This contract is not allowed to transfer sender's tokens");
        require(token.balanceOf(msg.sender, _tokenID) >= _tokenAmount, "The user has not enough tokens");

        orderCount++;

        Order memory newOrder = Order(_tokenAddress, payable(msg.sender), _tokenID, _tokenAmount, _deadline, _price, orderCount, OrderState.OPEN);
        ordersByID[orderCount] = newOrder;

        emit SellOrderCreated(orderCount, msg.sender, _tokenAddress, _tokenID, _tokenAmount, _deadline, _price);
    }

    function cancelOrder(uint _orderID) public {
        require(msg.sender == ordersByID[_orderID].seller, "You are not the owner of this order");
        require(ordersByID[_orderID].state == OrderState.OPEN, "The order is not active");

        ordersByID[_orderID].state = OrderState.CANCELED;

        emit SellOrderCanceled(_orderID);
    }

    function buyWithETH(uint _orderID) payable public {
        uint weiCost = (ordersByID[_orderID].price * 10 ** 36) / uint(getETHPrice() * 10 ** 10);

        require(ordersByID[_orderID].state == OrderState.OPEN, "The order is not available");
        require(msg.value >= weiCost, "Not enough ETH sended for this transaction");

        if (ordersByID[_orderID].deadline <= block.timestamp) {
            ordersByID[_orderID].state = OrderState.TIME_ENDED;
            
            emit SellOrderCanceled(_orderID);
            
            revert("The order has reached his deadline");
        }

        ERC1155 token = ERC1155(ordersByID[_orderID].tokenAddress);

        if (token.isApprovedForAll(ordersByID[_orderID].seller, address(this))) {
            ordersByID[_orderID].state = OrderState.ERROR_APPROVED;

            emit SellOrderCanceled(_orderID);

            revert("The seller has revoked access to their tokens to this contract");
        }

        if (token.balanceOf(ordersByID[_orderID].seller, ordersByID[_orderID].tokenID) >= ordersByID[_orderID].tokenAmount) {
            ordersByID[_orderID].state = OrderState.ERROR_AMOUNT;

            emit SellOrderCanceled(_orderID);

            revert("The seller doesn't have enough tokens");
        }

        (bool success, ) = msg.sender.call{value: msg.value - weiCost}("");
        require(success);

        ordersByID[_orderID].state = OrderState.DONE;

        (success, ) = ordersByID[_orderID].seller.call{value: (weiCost * 99) / 100}("");
        require(success);

        token.safeTransferFrom(ordersByID[_orderID].seller, msg.sender, ordersByID[_orderID].tokenID, ordersByID[_orderID].tokenAmount, "");

        emit SellOrderCompleted(_orderID, msg.sender);
    }

    function buyWithDAI(uint _orderID) public {
        uint DAICost = (ordersByID[_orderID].price * 10 ** 36) / uint(getDAIPrice() * 10 ** 10);

        require(ordersByID[_orderID].state == OrderState.OPEN, "The order is not available");

        if (ordersByID[_orderID].deadline <= block.timestamp) {
            ordersByID[_orderID].state = OrderState.TIME_ENDED;
            
            emit SellOrderCanceled(_orderID);
            
            revert("The order has reached his deadline");
        }

        ERC1155 token = ERC1155(ordersByID[_orderID].tokenAddress);

        if (token.isApprovedForAll(ordersByID[_orderID].seller, address(this))) {
            ordersByID[_orderID].state = OrderState.ERROR_APPROVED;

            emit SellOrderCanceled(_orderID);

            revert("The seller has revoked access to their tokens to this contract");
        }

        if (token.balanceOf(ordersByID[_orderID].seller, ordersByID[_orderID].tokenID) >= ordersByID[_orderID].tokenAmount) {
            ordersByID[_orderID].state = OrderState.ERROR_AMOUNT;

            emit SellOrderCanceled(_orderID);
            
            revert("The seller doesn't have enough tokens");
        }

        ERC20 coin = ERC20(DAIAddress);

        require(coin.allowance(msg.sender, address(this)) >= DAICost, "This contract is not allowed to transfer buyer's tokens");

        ordersByID[_orderID].state = OrderState.DONE;

        require(coin.transferFrom(msg.sender, address(this), (DAICost) / 100));
        require(coin.transferFrom(msg.sender, ordersByID[_orderID].seller, (DAICost * 99) / 100));

        token.safeTransferFrom(ordersByID[_orderID].seller, msg.sender, ordersByID[_orderID].tokenID, ordersByID[_orderID].tokenAmount, "");

        emit SellOrderCompleted(_orderID, msg.sender);
    }
    
    function buyWithLINK(uint _orderID) public {
        uint LINKCost = (ordersByID[_orderID].price * 10 ** 36) / uint(getLINKPrice() * 10 ** 10);

        require(ordersByID[_orderID].state == OrderState.OPEN, "The order is not available");

        if (ordersByID[_orderID].deadline <= block.timestamp) {
            ordersByID[_orderID].state = OrderState.TIME_ENDED;
            
            emit SellOrderCanceled(_orderID);
            
            revert("The order has reached his deadline");
        }

        ERC1155 token = ERC1155(ordersByID[_orderID].tokenAddress);

        if (token.isApprovedForAll(ordersByID[_orderID].seller, address(this))) {
            ordersByID[_orderID].state = OrderState.ERROR_APPROVED;

            emit SellOrderCanceled(_orderID);

            revert("The seller has revoked access to their tokens to this contract");
        }

        if (token.balanceOf(ordersByID[_orderID].seller, ordersByID[_orderID].tokenID) >= ordersByID[_orderID].tokenAmount) {
            ordersByID[_orderID].state = OrderState.ERROR_AMOUNT;

            emit SellOrderCanceled(_orderID);
            
            revert("The seller doesn't have enough tokens");
        }

        ERC20 coin = ERC20(LINKAddress);

        require(coin.allowance(msg.sender, address(this)) >= LINKCost, "This contract is not allowed to transfer buyer's tokens");

        ordersByID[_orderID].state = OrderState.DONE;

        require(coin.transferFrom(msg.sender, address(this), (LINKCost) / 100));
        require(coin.transferFrom(msg.sender, ordersByID[_orderID].seller, (LINKCost * 99) / 100));

        token.safeTransferFrom(ordersByID[_orderID].seller, msg.sender, ordersByID[_orderID].tokenID, ordersByID[_orderID].tokenAmount, "");

        emit SellOrderCompleted(_orderID, msg.sender);
    }

    function setAdminFee(uint _adminFee) public onlyRole(ADMIN_ROLE) {
        require(_adminFee >= 0 && _adminFee <= 100, "Wrong fee!");

        adminFee = _adminFee;
    }

    function setETHFedd(address _address) public onlyRole(ADMIN_ROLE) {
        ETHFeed = AggregatorV3Interface(_address);
    }

    function setDAIFedd(address _address) public onlyRole(ADMIN_ROLE) {
        DAIFeed = AggregatorV3Interface(_address);
    }

    function setLINKFedd(address _address) public onlyRole(ADMIN_ROLE) {
        LINKFeed = AggregatorV3Interface(_address);
    }

    function getETHPrice() private view returns (int) {
        ( , int price, , , ) = ETHFeed.latestRoundData();
        return price;
    }

    function getDAIPrice() private view returns (int) {
        ( , int price, , , ) = DAIFeed.latestRoundData();
        return price;
    }

    function getLINKPrice() private view returns (int) {
        ( , int price, , , ) = LINKFeed.latestRoundData();
        return price;
    }
}