// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import "hardhat/console.sol";

contract MockCCIP {
    // 记录目标合约和调用数据
    event CrossChainMessage(address target, bytes data);

    function sendMessage(address target, bytes calldata data) external payable {
        // 直接在本链调用目标合约
        // console.log('target:', target);
        // console.logBytes(data);

       (bool success,) = target.call{value: msg.value}(data);

        // require(success, "Cross-chain message failed");
        emit CrossChainMessage(target, data);
    }
}