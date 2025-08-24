const { ethers, deployments } = require("hardhat")
const { expect } = require("chai");

describe('NftActionSeller', () => {

    it('should be able to createNftAction', async () => {
      await main()
    })
})
async function getGasCost(tx) {
    const receipt = await tx.wait(); // tx 必须是 TransactionResponse
    const gasUsed = receipt.gasUsed;               // BigInt
    const gasPrice = receipt.gasPrice;    // BigInt
    console.log('gasUsed:', gasUsed, typeof gasUsed)
    console.log('gasPrice:', gasPrice, typeof gasPrice)

    return gasUsed * gasPrice;                     // wei
}

async function main() {

    const [deployer ,seller, buyer] = await ethers.getSigners();
    await deployments.fixture(["deployNftAction"]);
    const nftActionProxy = await deployments.get('NftActionProxy')
     const nftAction = await ethers.getContractAt("NftAction", nftActionProxy.address);
    const TestERC721 = await ethers.getContractFactory("TestERC721");
    // 如果中间省略connect默认就是取得getSigners的第一个地址去进行部署
    const testERC721 = await TestERC721.connect(deployer).deploy();

    await testERC721.waitForDeployment();
    const testERC721Address = await testERC721.getAddress();
    console.log("TestERC721 deployed to:", testERC721Address);

   

    for (let i = 0; i < 10; i++) {
        await testERC721.mint(seller.address, i + 1);
    }

    const tokenId = 1;
     // 授权NFT给代理合约
   await testERC721.connect(seller).setApprovalForAll(nftActionProxy.address, true);
    
    await nftAction.createNftAction(
        10,
        ethers.parseEther('1000'),
        testERC721Address,
        tokenId,
        seller.address,

    )
    const actionRes = await nftAction.nftActions(0)
    console.log('拍卖创建成功:', actionRes)
    
        console.log("买家信息", buyer.address, buyer.balance)

    // 买家购买
    const buyTx = await nftAction.connect(buyer).placeBidForEth(

        0,
        ethers.parseEther('2000'), 
        ethers.ZeroAddress,
        { value: ethers.parseEther('2000')}

    )
    /**
     * 不 执行await bidTx.wait()，那交易虽然发出去了，但 还没真正打包进区块。
        后面立刻调用 endNftAction，很可能报错（因为链上状态还没更新）。
     */

  const gasCostBuyer = await getGasCost(buyTx)
    

    
    // await new Promise((resolve) => setTimeout(resolve, 10 * 1000))
    // 用 hardhat evm 快进 10 秒，而不是 setTimeout
    await ethers.provider.send("evm_increaseTime", [10]);
    await ethers.provider.send("evm_mine");

    const endTx = await nftAction.connect(seller).endNftAction(0)
    //   容忍度
  const endGasCost = await getGasCost(endTx)
    

   const GAS_TOLERANCE = ethers.parseUnits("0.1", "ether"); // 0.1 ETH 容忍度
    const actionRes2 = await nftAction.nftActions(0)
    console.log('actionRes2:', actionRes2)
    const deployerBalance = await ethers.provider.getBalance(deployer);
    const sellerBalance = await ethers.provider.getBalance(seller);
    const buyerBalance = await ethers.provider.getBalance(buyer);
    console.log('deployerBalance:', Number(ethers.formatEther(String(deployerBalance))))
    console.log('sellerBalance:', Number(ethers.formatEther(String(sellerBalance))))
    console.log('buyerBalance:', Number(ethers.formatEther(String(buyerBalance))))
    console.log('gasCostBuyer:', Number(ethers.formatEther(String(gasCostBuyer))) * 10)
    console.log('endGasCost:', Number(ethers.formatEther(String(endGasCost))) * 10)

    // deployer 获得手续费 1 ETH = 10^18 wei ethers.parseEther ---> 单位是wei
    expect(Number(ethers.formatEther(deployerBalance))).to.be.closeTo(10200, Number(ethers.formatEther(gasCostBuyer + endGasCost)) * 100)

    // 卖家获得
    expect(Number(ethers.formatEther(sellerBalance))).to.be.closeTo(11800, Number(ethers.formatEther(endGasCost)) * 100)


    // 买家获得
    expect(Number(ethers.formatEther(buyerBalance))).to.be.closeTo(8000, Number(ethers.formatEther(gasCostBuyer)) * 100)



    // expect(actionRes2.highestBidder).to.equal(buyer.address)
    // expect(actionRes2.highestBid).to.equal(ethers.parseEther('0.01'))

    const owner = await testERC721.ownerOf(tokenId)
    console.log('owner:', owner)
    expect(owner).to.equal(buyer.address)
    // 检查买家是否收到了NFT
    expect(await testERC721.ownerOf(tokenId)).to.equal(buyer.address);



}
