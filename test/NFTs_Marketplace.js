const { expect } = require("chai");
const { ethers, network, upgrades } = require("hardhat");

describe("NFT's Marketplace", () => {
    let NFTsMarketplaceFactory, NFTsMarketplace, owner, user1, user2, user3, user4, user5, user6, user7, user8, user9;
    
    beforeEach(async () => {
        NFTsMarketplaceFactory = await ethers.getContractFactory("NFTsMarketplace");
        NFTsMarketplace = await upgrades.deployProxy(NFTsMarketplaceFactory);
        [owner, user1, user2, user3, user4, user5, user6, user7, user8, user9, _] = await ethers.getSigners();
    });
    
    describe("Deployment", () => {
        it("Should set the owner", async () => {
            expect(await NFTsMarketplace.isAdmin(owner.address)).to.be.equal(true);
        });
        
        it("Should set the variables", async () => {
            expect(await NFTsMarketplace.adminFee()).to.be.equal(1);
            expect(await NFTsMarketplace.orderCount()).to.be.equal(0);
            expect(await NFTsMarketplace.DAIAddress()).to.be.equal("0x95b58a6Bff3D14B7DB2f5cb5F0Ad413DC2940658");
            expect(await NFTsMarketplace.LINKAddress()).to.be.equal("0x01BE23585060835E02B77ef475b0Cc51aA1e0709");
        });
    });

    xdescribe("Seller actions", () => {
        it("Should let the user create a sell order", async () => {

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
