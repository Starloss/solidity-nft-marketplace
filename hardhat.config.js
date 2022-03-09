/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("dotenv").config();
require('@nomiclabs/hardhat-waffle');
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-deploy');
require('solidity-coverage');
 
module.exports = {
    solidity: {
        version: "0.8.11",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    defaultNetwork: "hardhat",
    networks: {
        rinkeby: {
            url: process.env.INFURA_URL,
            accounts: [`0x${process.env.PRIVATE_KEY}`]
        },
        hardhat: {
            forking: {
              url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
              blockNumber: 14348431
            }
        }
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY
    },
    namedAccounts: {
        deployer: 0,
        user1: 1,
        user2: 2
    },
};