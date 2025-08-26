# NFT 拍卖市场完成的功能：

    ✅ ERC721 标准（NFT 转移 + 铸造）

	✅ 创建拍卖（NFT 上架）

	✅ 出价（ETH 出价，ERC20 参数已预留）

	✅ 可升级（透明代理模式）
	
    ✅ 工厂模式（每个拍卖独立合约）
	
	✅ Chainlink 预言机（价格换算）
    
### 部署脚本和测试脚本

	部署deploy/01_nft_action.js 后 再去运行测试代码：  singleSellerTest.js / mutipleSellerTest.js
	部署deploy/03_nft_action_factory.js与02_nft_upgrade_action.js后再去运行测试代码：mutipleSellerFactoryTest.js
    
# 未完成功能：
	❌ 跨链拍卖（CCIP）

    
# Sample Hardhat Project



This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```
