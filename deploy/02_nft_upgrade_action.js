const { upgrades, ethers } = require("hardhat")


const fs = require("fs");
const path = require("path");
const cacheDir = path.join(__dirname, ".cache");
module.exports = async ({getNamedAccounts, deployments}) => {
  const { save } = deployments;
const {deployer} = await getNamedAccounts();
  const storePath = path.resolve(__dirname, "./.cache/proxyNftAuctionFactory.json");
  const storeData = fs.readFileSync(storePath, "utf-8");
  const { nftProxyAddress, implmentAddress, abi } = JSON.parse(storeData);
  console.log('nftProxyAddress:', nftProxyAddress, deployer)
  
  const NftActionSingleupgrade = await ethers.getContractFactory('NftActionSingleupgradeTest')


  const NftActionSingleupgradeTestObj = await upgrades.upgradeProxy(
    nftProxyAddress, 
    NftActionSingleupgrade
)
    await NftActionSingleupgradeTestObj.waitForDeployment()
    const nftProxyAddressV2 = await NftActionSingleupgradeTestObj.getAddress()
  console.log('nftProxyAddressV2:', nftProxyAddressV2)





await save('NftActionProxyTestV2', {

  address: nftProxyAddressV2,
  abi,

})


};
module.exports.tags = ['deployNftActionTestV2'];