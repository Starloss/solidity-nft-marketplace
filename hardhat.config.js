/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("dotenv").config();
require('@nomiclabs/hardhat-waffle');
require('@openzeppelin/hardhat-upgrades');
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
              url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
              blockNumber: 10288039
            }
        }
    }
};