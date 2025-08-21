const { ethers, deployments } = require("hardhat")
const { expect } = require("chai");

describe('NftActionSeller', () => {

    it('should be able to createNftAction', async () => {
      await main()
    })
})


async function main() {

    const [seller, buyer] = await ethers.getSigners();
    await deployments.fixture(["deployNftAction"]);
    const nftActionProxy = await deployments.get('NftActionProxy')
     const nftAction = await ethers.getContractAt("NftAction", nftActionProxy.address);
    const TestERC721 = await ethers.getContractFactory("TestERC721");
    const testERC721 = await TestERC721.deploy();
    await testERC721.waitForDeployment();
    const testERC721Address = await testERC721.getAddress();
    console.log("TestERC721 deployed to:", testERC721Address);
   const TestERC720 = await ethers.getContractFactory("TestERC720");
    const testERC720 = await TestERC720.deploy();
    await testERC720.waitForDeployment();
    // usdc 代币
    const usdcAddress = await testERC720.getAddress();
    console.log("TestERC720 deployed to:", testERC720Address);
    // 给购买者分点币用来测试
    let tx = await testERC720.connect(seller).mint(buyer, ethers.parseEther('1000'));
    await tx.wait();
    const aggreagatorV3 = await ethers.getContractFactory("AggreagatorV3")
   
    const priceFeedEthDeploy = await aggreagatorV3.deploy(ethers.parseEther("10000"))
    await priceFeedEthDeploy.waitForDeployment()
    const priceFeedEthAddress = await priceFeedEthDeploy.getAddress()
    console.log("priceFeedEthAddress deployed to:", priceFeedEthAddress);
    const priceFeedUsdcDeploy = await aggreagatorV3.deploy(ethers.parseEther("1"))
    await priceFeedUsdcDeploy.waitForDeployment()
    const priceFeedUsdcAddress = await priceFeedUsdcDeploy.getAddress()
    console.log("priceFeed_UsdcAddress deployed to:", priceFeedUsdcAddress);
    
    const tokenUsd = [{
        tokenAddress: usdcAddress,
        priceFeedAddress: priceFeedUsdcAddress,

    },{
        tokenAddress: ethers.constants.AddressZero,
        priceFeedAddress: priceFeedEthAddress,

    }]

    await Promise.all(tokenUsd.forEach(async (item) => {
        const { tokenAddress, priceFeedAddress } = item;
        await nftAction.setPriceFeed(tokenAddress, priceFeedAddress)
    }))

    for (let i = 0; i < 10; i++) {
        await testERC721.mint(seller.address, i + 1);
    }

    const tokenId = 1;
   await testERC721.connect(seller).setApprovalForAll(nftActionProxy.address, true);
    
    await nftAction.createNftAction(
        10,
        ethers.parseEther('0.01'),
        testERC721Address,
        tokenId,
    )
    const actionRes = await nftAction.nftActions(0)
    console.log('拍卖创建成功:', actionRes)
    
    
    // 买家购买
    await nftAction.connect(buyer).placeBid(0, {
        value: ethers.parseEther('0.01'),
    })
    
    await new Promise((resolve) => setTimeout(resolve, 10 * 1000))

   await nftAction.connect(seller).endNftAction(0)
    const actionRes2 = await nftAction.nftActions(0)
    console.log('actionRes2:', actionRes2)
    expect(actionRes2.highestBidder).to.equal(buyer.address)
    expect(actionRes2.highestBid).to.equal(ethers.parseEther('0.01'))

    const owner = await testERC721.ownerOf(tokenId)
    console.log('owner:', owner)
    expect(owner).to.equal(buyer.address)
    // 检查买家是否收到了NFT
    expect(await testERC721.ownerOf(tokenId)).to.equal(buyer.address);



}
