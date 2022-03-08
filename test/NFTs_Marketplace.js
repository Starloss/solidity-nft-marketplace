const { expect } = require("chai");
const { ethers, network, upgrades } = require("hardhat");

describe("NFT's Marketplace", () => {
    let NFTsMarketplaceFactory, NFTsMarketplace, ERC1155Factory, ERC1155Token;
    let owner, user1, user2, user3, user4, user5, user6, user7, user8, user9;
    
    beforeEach(async () => {
        NFTsMarketplaceFactory = await ethers.getContractFactory("NFTsMarketplace");
        NFTsMarketplace = await upgrades.deployProxy(NFTsMarketplaceFactory);
        [owner, user1, user2, user3, user4, user5, user6, user7, user8, user9, _] = await ethers.getSigners();

        ERC1155Factory = await ethers.getContractFactory("ERC1155Token");
        ERC1155Token = await ERC1155Factory.deploy();
    });
    
    describe("Deployment", () => {
        it("Should set the owner", async () => {
            expect(await NFTsMarketplace.isAdmin(owner.address)).to.be.equal(true);
        });
        
        it("Should set the variables", async () => {
            expect(await NFTsMarketplace.adminFee()).to.be.equal(1);
            expect(await NFTsMarketplace.orderCount()).to.be.equal(0);
            expect(await NFTsMarketplace.DAIAddress()).to.be.equal("0x6B175474E89094C44Da98b954EedeAC495271d0F");
            expect(await NFTsMarketplace.LINKAddress()).to.be.equal("0x514910771AF9Ca656af840dff83E8264EcF986CA");
        });
    });

    describe("Seller actions", () => {
        it("Should let the user create a sell order", async () => {
            await ERC1155Token.mint(user1.address, 1, 100);
            await ERC1155Token.connect(user1).setApprovalForAll(NFTsMarketplace.address, true);

            await NFTsMarketplace.connect(user1).createNewOrder(ERC1155Token.address, 1, 100, 259200, 100);
            const order = await NFTsMarketplace.ordersByID(1);

            expect(await NFTsMarketplace.orderCount()).to.be.equal(1);
            expect(order.seller).to.be.equal(user1.address);
        });

        it("Should let the user cancel a own order", async () => {
            await ERC1155Token.mint(user1.address, 1, 100);
            await ERC1155Token.connect(user1).setApprovalForAll(NFTsMarketplace.address, true);

            await NFTsMarketplace.connect(user1).createNewOrder(ERC1155Token.address, 1, 100, 259200, 100);
            let order = await NFTsMarketplace.ordersByID(1);

            await NFTsMarketplace.connect(user1).cancelOrder(order.ID);
            order = await NFTsMarketplace.ordersByID(1);

            expect(order.state).to.be.equal(2);
        });
    });

    describe("Buyer actions", () => {
        it("Should let the user buy a token listed", async () => {
            
        });
    });

    xdescribe("Upgrading NFT's Marketplace", () => {
        let NFTsMarketplaceFactoryV2, NFTsMarketplaceV2;
        beforeEach(async () => {
            NFTsMarketplaceFactoryV2 = await ethers.getContractFactory("NFTsMarketplaceV2");
            NFTsMarketplaceV2 = await upgrades.upgradeProxy(instance.address, NFTsMarketplaceFactoryV2);
        });
    });
});
