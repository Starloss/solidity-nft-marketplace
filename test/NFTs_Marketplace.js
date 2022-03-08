const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");
const { ethers, network, upgrades, waffle } = require("hardhat");

const provider = waffle.provider;

const DAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const DAIABI = [{"inputs":[{"internalType":"uint256","name":"chainId_","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"guy","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":true,"inputs":[{"indexed":true,"internalType":"bytes4","name":"sig","type":"bytes4"},{"indexed":true,"internalType":"address","name":"usr","type":"address"},{"indexed":true,"internalType":"bytes32","name":"arg1","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"arg2","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"data","type":"bytes"}],"name":"LogNote","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"dst","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"}],"name":"deny","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"mint","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"move","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"holder","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"expiry","type":"uint256"},{"internalType":"bool","name":"allowed","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"pull","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"push","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"}],"name":"rely","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"wards","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}];
const LINKAddress = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
const LINKABI = [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"},{"name":"_data","type":"bytes"}],"name":"transferAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_subtractedValue","type":"uint256"}],"name":"decreaseApproval","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_addedValue","type":"uint256"}],"name":"increaseApproval","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":false,"name":"data","type":"bytes"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"}];

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
        beforeEach(async () => {
            await ERC1155Token.mint(user1.address, 1, 100);
            await ERC1155Token.connect(user1).setApprovalForAll(NFTsMarketplace.address, true);

            await NFTsMarketplace.connect(user1).createNewOrder(ERC1155Token.address, 1, 100, 259200, 10);
        });

        it("Should let the user buy a token listed with ETH", async () => {
            let user1BalanceBefore = parseFloat(ethers.utils.formatEther(await provider.getBalance(user1.address)));
            let user2BalanceBefore = parseFloat(ethers.utils.formatEther(await provider.getBalance(user2.address)));
            let contractBalanceBefore = parseFloat(ethers.utils.formatEther(await provider.getBalance(NFTsMarketplace.address)));

            await NFTsMarketplace.connect(user2).buyWithETH(1, { value: parseEther("1") });

            let user1BalanceAfter = parseFloat(ethers.utils.formatEther(await provider.getBalance(user1.address)));
            let user2BalanceAfter = parseFloat(ethers.utils.formatEther(await provider.getBalance(user2.address)));
            let contractBalanceAfter = parseFloat(ethers.utils.formatEther(await provider.getBalance(NFTsMarketplace.address)));
            
            let order = await NFTsMarketplace.ordersByID(1);

            expect(order.state).to.be.equal(1);
            expect(user1BalanceAfter < user1BalanceBefore + 0.1 && user1BalanceAfter > user1BalanceBefore).to.be.equal(true);
            expect(user2BalanceAfter > user2BalanceBefore - 0.1 && user2BalanceAfter < user2BalanceBefore).to.be.equal(true);
            expect(contractBalanceAfter > contractBalanceBefore).to.be.equal(true);
            expect(await ERC1155Token.balanceOf(await user1.address, 1)).to.be.equal(0);
            expect(await ERC1155Token.balanceOf(await user2.address, 1)).to.be.equal(100);
        });

        it("Should let the user buy a token listed with DAI", async () => {
            const DAIContract = await hre.ethers.getContractAt(DAIABI, DAIAddress);
            await hre.network.provider.request({
                method: "hardhat_impersonateAccount",
                params: ["0xC411568e31AB9B6B7418a5Dcfb44958DbF549C57"],
            });
            const DAIOwner = await ethers.getSigner("0xC411568e31AB9B6B7418a5Dcfb44958DbF549C57");
            
            await DAIContract.connect(DAIOwner).transfer(user2.address, await DAIContract.balanceOf(DAIOwner.address));
            await DAIContract.connect(user2).approve(NFTsMarketplace.address, await DAIContract.balanceOf(user2.address));

            let user1BalanceBefore = await DAIContract.balanceOf(await user1.address);
            let user2BalanceBefore = await DAIContract.balanceOf(await user2.address);
            let contractBalanceBefore = await DAIContract.balanceOf(await NFTsMarketplace.address);
            
            await NFTsMarketplace.connect(user2).buyWithDAI(1);
            
            let user1BalanceAfter = await DAIContract.balanceOf(await user1.address);
            let user2BalanceAfter = await DAIContract.balanceOf(await user2.address);
            let contractBalanceAfter = await DAIContract.balanceOf(await NFTsMarketplace.address);

            let order = await NFTsMarketplace.ordersByID(1);

            expect(order.state).to.be.equal(1);
            expect(user1BalanceAfter > user1BalanceBefore).to.be.equal(true);
            expect(user2BalanceAfter < user2BalanceBefore).to.be.equal(true);
            expect(contractBalanceAfter > contractBalanceBefore).to.be.equal(true);
            expect(await ERC1155Token.balanceOf(await user1.address, 1)).to.be.equal(0);
            expect(await ERC1155Token.balanceOf(await user2.address, 1)).to.be.equal(100);
        });

        it("Should let the user buy a token listed with LINK", async () => {
            const LINKContract = await hre.ethers.getContractAt(LINKABI, LINKAddress);
            await hre.network.provider.request({
                method: "hardhat_impersonateAccount",
                params: ["0xDFd5293D8e347dFe59E90eFd55b2956a1343963d"],
            });
            const LINKOwner = await ethers.getSigner("0xDFd5293D8e347dFe59E90eFd55b2956a1343963d");
            
            await LINKContract.connect(LINKOwner).transfer(user2.address, await LINKContract.balanceOf(LINKOwner.address));
            await LINKContract.connect(user2).approve(NFTsMarketplace.address, await LINKContract.balanceOf(user2.address));

            let user1BalanceBefore = await LINKContract.balanceOf(await user1.address);
            let user2BalanceBefore = await LINKContract.balanceOf(await user2.address);
            let contractBalanceBefore = await LINKContract.balanceOf(await NFTsMarketplace.address);
            
            await NFTsMarketplace.connect(user2).buyWithLINK(1);
            
            let user1BalanceAfter = await LINKContract.balanceOf(await user1.address);
            let user2BalanceAfter = await LINKContract.balanceOf(await user2.address);
            let contractBalanceAfter = await LINKContract.balanceOf(await NFTsMarketplace.address);

            let order = await NFTsMarketplace.ordersByID(1);

            expect(order.state).to.be.equal(1);
            expect(user1BalanceAfter > user1BalanceBefore).to.be.equal(true);
            expect(user2BalanceAfter < user2BalanceBefore).to.be.equal(true);
            expect(contractBalanceAfter > contractBalanceBefore).to.be.equal(true);
            expect(await ERC1155Token.balanceOf(await user1.address, 1)).to.be.equal(0);
            expect(await ERC1155Token.balanceOf(await user2.address, 1)).to.be.equal(100);
        });
    });

    xdescribe("Upgrading NFT's Marketplace", () => {
        let NFTsMarketplaceFactoryV2, NFTsMarketplaceV2;

        beforeEach(async () => {
            NFTsMarketplaceFactoryV2 = await ethers.getContractFactory("NFTsMarketplaceV2");
            NFTsMarketplaceV2 = await upgrades.upgradeProxy(NFTsMarketplace.address, NFTsMarketplaceFactoryV2);
        });

        describe("Deployment", () => {
            it("Should set the owner", async () => {
                expect(await NFTsMarketplaceV2.isAdmin(owner.address)).to.be.equal(true);
            });
            
            it("Should set the variables", async () => {
                expect(await NFTsMarketplaceV2.adminFee()).to.be.equal(1);
                expect(await NFTsMarketplaceV2.orderCount()).to.be.equal(0);
                expect(await NFTsMarketplaceV2.DAIAddress()).to.be.equal("0x6B175474E89094C44Da98b954EedeAC495271d0F");
                expect(await NFTsMarketplaceV2.LINKAddress()).to.be.equal("0x514910771AF9Ca656af840dff83E8264EcF986CA");
            });
        });
    });
});
