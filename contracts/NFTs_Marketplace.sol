/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract NFTsMarketplace is AccessControlUpgradeable {

    /// VARIABLES
    uint public adminFee;
    uint public orderCount;

    AggregatorV3Interface internal ETHFeed;
    AggregatorV3Interface internal DAIFeed;
    AggregatorV3Interface internal LINKFeed;

    address public DAIAddress;
    address public LINKAddress;

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
        uint ID;
        OrderState state;
    }
    
    mapping(uint => Order) public ordersByID;

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

    modifier orderIsAvailable(uint _orderID) {
        require(
            ordersByID[_orderID].state == OrderState.OPEN,
            "The order is not available"
        );
        _;
    }

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
     */
    function initialize() public initializer {
        __AccessControl_init();

        _grantRole(ADMIN_ROLE, msg.sender);

        adminFee = 1;
        orderCount = 0;

        ETHFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        DAIFeed = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
        LINKFeed = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);

        DAIAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        LINKAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    }

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

    function cancelOrder(uint _orderID)
        public
        orderIsAvailable(_orderID)
        ownerOfOrder(_orderID)
    {
        ordersByID[_orderID].state = OrderState.CANCELED;

        emit SellOrderCanceled(_orderID);
    }

    function buyWithETH(uint _orderID) payable public orderIsAvailable(_orderID) {
        uint weiCost = (ordersByID[_orderID].price * 10 ** 36) / uint(getETHPrice() * 10 ** 10);

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

        if (
            token.balanceOf(
                ordersByID[_orderID].seller,
                ordersByID[_orderID].tokenID
            ) >= ordersByID[_orderID].tokenAmount
        ) {
            ordersByID[_orderID].state = OrderState.ERROR_AMOUNT;

            emit SellOrderCanceled(_orderID);

            revert("The seller doesn't have enough tokens");
        }

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

    function buyWithDAI(uint _orderID) public orderIsAvailable(_orderID) {
        uint DAICost = (ordersByID[_orderID].price * 10 ** 36) / uint(getDAIPrice() * 10 ** 10);

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

        if (
            token.balanceOf(
                ordersByID[_orderID].seller,
                ordersByID[_orderID].tokenID
            ) >= ordersByID[_orderID].tokenAmount
        ) {
            ordersByID[_orderID].state = OrderState.ERROR_AMOUNT;

            emit SellOrderCanceled(_orderID);
            
            revert("The seller doesn't have enough tokens");
        }

        ERC20 coin = ERC20(DAIAddress);

        require(
            coin.allowance(msg.sender, address(this)) >= DAICost,
            "This contract is not allowed to transfer buyer's tokens"
        );

        ordersByID[_orderID].state = OrderState.DONE;

        require(
            coin.transferFrom(
                msg.sender, address(this),
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
    
    function buyWithLINK(uint _orderID) public orderIsAvailable(_orderID) {
        uint LINKCost = (ordersByID[_orderID].price * 10 ** 36) / uint(getLINKPrice() * 10 ** 10);

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

        if (
            token.balanceOf(
                ordersByID[_orderID].seller,
                ordersByID[_orderID].tokenID
            ) >= ordersByID[_orderID].tokenAmount
        ) {
            ordersByID[_orderID].state = OrderState.ERROR_AMOUNT;

            emit SellOrderCanceled(_orderID);
            
            revert("The seller doesn't have enough tokens");
        }

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

    function setAdminFee(uint _adminFee) external onlyRole(ADMIN_ROLE) {
        require(_adminFee >= 0 && _adminFee <= 10, "Wrong fee!");

        adminFee = _adminFee;
    }

    function setETHFedd(address _address) external onlyRole(ADMIN_ROLE) {
        ETHFeed = AggregatorV3Interface(_address);
    }

    function setDAIFedd(address _address) external onlyRole(ADMIN_ROLE) {
        DAIFeed = AggregatorV3Interface(_address);
    }

    function setLINKFedd(address _address) external onlyRole(ADMIN_ROLE) {
        LINKFeed = AggregatorV3Interface(_address);
    }

    function setDAIAddress(address _address) external onlyRole(ADMIN_ROLE) {
        DAIAddress = _address;
    }

    function setLINKAddress(address _address) external onlyRole(ADMIN_ROLE) {
        LINKAddress = _address;
    }

    function isAdmin(address _address) external view returns (bool) {
        return(hasRole(ADMIN_ROLE, _address));
    }

    function getETHPrice() internal view returns (int) {
        ( , int price, , , ) = ETHFeed.latestRoundData();
        return price;
    }

    function getDAIPrice() internal view returns (int) {
        ( , int price, , , ) = DAIFeed.latestRoundData();
        return price;
    }

    function getLINKPrice() internal view returns (int) {
        ( , int price, , , ) = LINKFeed.latestRoundData();
        return price;
    }
}