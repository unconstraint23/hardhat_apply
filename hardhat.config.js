require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades')
require("hardhat-deploy")


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts: {
     deployer: 0,
    user1: 1,
    user2: 2,

  }
};
