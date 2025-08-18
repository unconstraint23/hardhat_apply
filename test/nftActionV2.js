const { ethers, deployments } = require('hardhat')
const { expect } = require('chai')

describe('NftActionsV2 upgrade', () => {
    /**
     * 步骤：
     * 1. 部署NftAction合约
     * 2. 调用createNftAction
     * 3. 升级NftAction合约--->NftActionV2
     * 4. 调用NftActionV2合约

     */
    it('should be able to deploy', async () => {
        // 1. 部署业务合约
        await deployments.fixture(['deployNftAction'])
        const nftActionProxy = await deployments.get('NftActionProxy')
        console.log('nftActionProxy:', nftActionProxy)
        const nftActionContract = await ethers.getContractAt('NftAction', nftActionProxy.address)

        // 2. 调用createNftAction

        await nftActionContract.createNftAction(
            100 * 1000,
            ethers.parseEther('0.01'),
            ethers.ZeroAddress,
            1,
        )

        const actionRes = await nftActionContract.nftActions(0)
        console.log('actionRes:', actionRes)
        const implmentAddress1 = await upgrades.erc1967.getImplementationAddress(nftActionProxy.address)
        console.log('implmentAddress:', implmentAddress1)

        // 3. 升级合约
        await deployments.fixture(['deployNftActionV2'])
        const actionRes2 = await nftActionContract.nftActions(0)
        const implmentAddress2 = await upgrades.erc1967.getImplementationAddress(nftActionProxy.address)
        console.log('implmentAddress2:', implmentAddress2)

        console.log('actionRes2:', actionRes2)

         const nftAuctionV2 = await ethers.getContractAt(
        "NftActionV2",
        nftActionProxy.address
      );
    const hello = await nftAuctionV2.testHello()
    console.log("hello::", hello);

        expect(actionRes2.startTime).to.equal(actionRes.startTime)
        expect(implmentAddress1.toLowerCase()).to.not.equal(implmentAddress2.toLowerCase()) 


    })
})
