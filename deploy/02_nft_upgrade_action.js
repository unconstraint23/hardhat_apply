const { deployments, upgrades, ethers } = require("hardhat")


const fs = require("fs");
const path = require("path");
const cacheDir = path.join(__dirname, ".cache");
module.exports = async ({getNamedAccounts, deployments}) => {
//   const { save } = deployments;
//   const {deployer} = await getNamedAccounts();
//   console.log('deployer:', deployer)
//   const nftActionV2 = await ethers.getContractFactory('NftActionV2')
//     const storePath = path.resolve(__dirname, "./.cache/proxyNftAuction.json");
//   const storeData = fs.readFileSync(storePath, "utf-8");
//   const { nftProxyAddress, implmentAddress, abi } = JSON.parse(storeData);
//   const nftActionContractV2 = await upgrades.upgradeProxy(
//     nftProxyAddress, 
//     nftActionV2,
//     { call: "admin" }
// )
//     await nftActionContractV2.waitForDeployment()
//     const nftProxyAddressV2 = await nftActionContractV2.getAddress()





// await save('NftActionProxyV2', {

//   address: nftProxyAddressV2,
//   abi,

// })


};
module.exports.tags = ['deployNftActionV2'];