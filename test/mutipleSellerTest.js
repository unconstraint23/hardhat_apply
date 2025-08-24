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
    const testERC721 = await TestERC721.deploy();
    await testERC721.waitForDeployment();
    const testERC721Address = await testERC721.getAddress();
    console.log("TestERC721 deployed to:", testERC721Address);
   const TestERC20 = await ethers.getContractFactory("TestERC20",deployer);
    const testERC20 = await TestERC20.deploy();

    await testERC20.waitForDeployment();
    // usdc 代币
    const usdcAddress = await testERC20.getAddress();
    console.log("TestERC20 deployed to:", usdcAddress);
    // 给购买者分点币用来测试
    let tx = await testERC20.connect(deployer).transfer(buyer.address, ethers.parseEther('1000'));
     await testERC20.connect(deployer).transfer(seller.address, ethers.parseEther("1000"));
    await tx.wait();
     // 确认余额
    const buyerBal = await testERC20.balanceOf(buyer.address);
    const sellerBal = await testERC20.balanceOf(seller.address);
    console.log("Buyer balance:", ethers.formatEther(buyerBal));
    console.log("Seller balance:", ethers.formatEther(sellerBal));
    const aggreagatorV3 = await ethers.getContractFactory("AggreagatorV3")
   
    const priceFeedEthDeploy = await aggreagatorV3.deploy(10000)
    await priceFeedEthDeploy.waitForDeployment()
    const priceFeedEthAddress = await priceFeedEthDeploy.getAddress()
    console.log("priceFeedEthAddress deployed to:", priceFeedEthAddress);
    const priceFeedUsdcDeploy = await aggreagatorV3.deploy(1)
    await priceFeedUsdcDeploy.waitForDeployment()
    const priceFeedUsdcAddress = await priceFeedUsdcDeploy.getAddress()
    console.log("priceFeed_UsdcAddress deployed to:", priceFeedUsdcAddress);
    const tokenUsd = [{
        tokenAddress: usdcAddress,
        priceFeedAddress: priceFeedUsdcAddress,

    },{
        tokenAddress: ethers.ZeroAddress,
        priceFeedAddress: priceFeedEthAddress,

    }]

    await Promise.all(tokenUsd.map(async (item) => {
        const { tokenAddress, priceFeedAddress } = item;
       return await nftAction.setPriceFeeds(tokenAddress, priceFeedAddress)
    }))

    for (let i = 0; i < 10; i++) {
        await testERC721.mint(seller.address, i + 1);
    }

    const tokenId = 1;
   await testERC721.connect(seller).setApprovalForAll(nftActionProxy.address, true);
    
    await nftAction.createNftAction(
        10,
        ethers.parseEther('0.00001'),
        testERC721Address,
        tokenId,
        seller.address
    )
    const actionRes = await nftAction.nftActions(0)
    console.log('拍卖创建成功:', actionRes)
    
    const beforeBuyer = await ethers.provider.getBalance(buyer);
    const beforeSeller = await ethers.provider.getBalance(seller);
    const beforeUSDC = await testERC20.balanceOf(buyer.address);
    console.log('beforeBuyer:', beforeBuyer)
    console.log('beforeSeller:', beforeSeller)
    console.log('beforeUSDC:', beforeUSDC)

    // 买家购买 eth购买
   tx = await nftAction.connect(buyer).placeBid(
    0, 
    0,
    ethers.ZeroAddress,
    {
        value: ethers.parseEther('0.000012'),
    })
    await tx.wait()

   tx = await testERC20.connect(buyer).approve(nftActionProxy.address, ethers.MaxUint256)
   await tx.wait()
   tx = await nftAction.connect(buyer).placeBid(
    0,
    ethers.parseEther('2'),
    usdcAddress
   )
   await tx.wait()

   const gasCost = await getGasCost(tx)
    console.log('gasCost:', gasCost)


    
  await ethers.provider.send("evm_increaseTime", [10]);
    await ethers.provider.send("evm_mine");

  const endTx = await nftAction.connect(seller).endNftAction(0)
    const endGasCost = await getGasCost(endTx)
    console.log('endGasCost:', endGasCost)
    const actionRes2 = await nftAction.nftActions(0)
    console.log('actionRes2:', actionRes2)
    const deployerBalance = await ethers.provider.getBalance(deployer);
    const sellerBalance = await ethers.provider.getBalance(seller);
    const buyerBalance = await ethers.provider.getBalance(buyer);
    const usdcBalance = await testERC20.balanceOf(buyer.address)
    const sellerUsdc = await testERC20.balanceOf(seller.address);
    const feeRecipientUsdc = await testERC20.balanceOf(feeRecipient);
    console.log('deployerBalance:', deployerBalance)
    console.log('sellerBalance:', sellerBalance)
    console.log('buyerBalance:', buyerBalance)
    console.log('usdcBalance:', usdcBalance)

    expect(actionRes2.highestBidder).to.equal(buyer.address)
    // expect(actionRes2.highestBid).to.equal(ethers.parseEther('0.01'))
    // expect(actionRes2.highestBid).to.be.closeTo(ethers.parseEther('2'))

    const owner = await testERC721.ownerOf(tokenId)
    console.log('owner:', owner)
    expect(owner).to.equal(buyer.address)
    // 检查买家是否收到了NFT
    expect(await testERC721.ownerOf(tokenId)).to.equal(buyer.address);



}
