const { ethers } = require('hardhat')

describe('Starting NftActions', () => {
    it('should deploy', async () => {
        const nftAction = await ethers.getContractFactory('NftAction')
        const nftActionContract = await nftAction.deploy()
        await nftActionContract.waitForDeployment()
        console.log('nftActionContract deployed to:', nftActionContract.address)
        await nftActionContract.createNftAction(
            100 * 1000,
            ethers.parseEther('0.00000001'),
            ethers.ZeroAddress,
            1,
        )
        const nftActionId = await nftActionContract.nextNftActionId()
        console.log('nftActionId:', nftActionId)
        const nftActionInfo = await nftActionContract.nftActions(nftActionId)
        console.log('nftActionInfo:', nftActionInfo)

        const action = await nftActionContract.nftActions(0)
        console.log('action:', action)

    })
})
