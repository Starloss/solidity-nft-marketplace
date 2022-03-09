const CONTRACT_NAME = "NFTsMarketplace";

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // Upgradeable Proxy
  await deploy("NFTsMarketplace", {
    from: deployer,
    proxy: {
      owner: deployer,
      execute: {
        init: {
          methodName: "initialize"
        },
      },
    },

    log: true,
  });
};

module.exports.tags = [CONTRACT_NAME];