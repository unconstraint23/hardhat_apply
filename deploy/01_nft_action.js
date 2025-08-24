const { deployments, upgrades, ethers } = require("hardhat")

const fs = require("fs");
const path = require("path");
const cacheDir = path.join(__dirname, ".cache");
module.exports = async ({getNamedAccounts, deployments}) => {
  const { save } = deployments;
  const {deployer, seller} = await getNamedAccounts();
  console.log('deployer:', deployer, "seller:", seller)

  const nftAction = await ethers.getContractFactory('NftAction')
  const nftActionContractProxy = await upgrades.deployProxy(nftAction, [deployer, seller], {

    initializer: 'initialize',
  })
  await nftActionContractProxy.waitForDeployment()
const nftProxyAddress = await nftActionContractProxy.getAddress()
  console.log('nftProxyAddress:', nftProxyAddress)
  const implmentAddress = await upgrades.erc1967.getImplementationAddress(nftProxyAddress)
console.log('实现合约地址：', implmentAddress)

const storePath = path.join(cacheDir, "proxyNftAuction.json")

fs.writeFileSync(storePath, JSON.stringify({
  nftProxyAddress,
  implmentAddress,
  abi: nftAction.interface.format("json"),
}))

await save('NftActionProxy', {
  address: nftProxyAddress,
  abi: nftAction.interface.format("json"),
})


};
module.exports.tags = ['deployNftAction'];

/**
 * 首先执行npx hardhat node 会启动一个持久化本地链

启动后会监听 HTTP RPC（默认 http://127.0.0.1:8545），并且会生成一批固定的测试账户（就是你 namedAccounts 里 0, 1, 2 对应的那些）。

这个本地链会保存部署过的合约地址、交易历史等信息，直到你重启 npx hardhat node 才会清空状态。
 * 然后执行npx hardhat deploy --network localhost 会在本地链部署合约
这里的 --network localhost 是告诉 Hardhat 连接到已经运行的本地节点（也就是 npx hardhat node 启动的链）。

Hardhat Deploy 插件会读取 namedAccounts，然后用 deployer（index 0 的账户）去部署合约。

部署完成后，它会在本地链的状态里记录下合约地址。
💡
所以当你切回 npx hardhat node 终端时，你能看到这些地址是因为这两步操作连的同一条链。

 总结
1、你能在 npx hardhat node 的控制台看到合约地址，是因为：

2、先启动了持久化的本地链（npx hardhat node）。

3、再用同一个网络 localhost 部署合约，写进了链的状态。

两个命令都连接到同一条链，所以地址能直接查到。
 */
