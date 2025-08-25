const { deployments, upgrades, ethers } = require("hardhat")

const fs = require("fs");
const path = require("path");
const cacheDir = path.join(__dirname, ".cache");
module.exports = async ({getNamedAccounts, deployments}) => {
  const { save } = deployments;
  const {deployer, seller} = await getNamedAccounts();
  console.log('deployer:', deployer, "seller:", seller)

  const NftActionOfFactory = await ethers.getContractFactory('NftActionOfFactory')
  const nftActionContractProxy = await upgrades.deployProxy(NftActionOfFactory, [deployer, seller], {

    initializer: 'initialize',
  })
  await nftActionContractProxy.waitForDeployment()
const nftProxyAddress = await nftActionContractProxy.getAddress()
  console.log('nftProxyAddress:', nftProxyAddress)
  const implmentAddress = await upgrades.erc1967.getImplementationAddress(nftProxyAddress)
console.log('实现合约地址：', implmentAddress)

const storePath = path.join(cacheDir, "proxyNftAuctionFactory.json")


fs.writeFileSync(storePath, JSON.stringify({
  nftProxyAddress,
  implmentAddress,
  abi: NftActionOfFactory.interface.format("json"),
}))

await save('NftActionOfFactoryProxy', {
  address: nftProxyAddress,
  abi: NftActionOfFactory.interface.format("json"),
})


};
module.exports.tags = ['deployNftActionOfFactory'];
