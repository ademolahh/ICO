const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log("Deploying......");

  const token = await deploy("Token", {
    from: deployer,
    args: [],
    log: true,
  });
  log("==========Contract Deployed Successfully==========");
  log(`Token deployed to ${token.address}`);

  const ico = await deploy("ICO", {
    from: deployer,
    args: [token.address],
    log: true,
  });
  log("==========Contract Deployed Successfully==========");
  log(`ICO deployed to ${ico.address}`);
};

module.exports.tags = ["all", "lock"];
