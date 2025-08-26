// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./NftActionOfFactory.sol";


contract NftActionSingleupgradeTest is NftActionOfFactory {
    // address public admin;
//     address public feeRecipient;
//     address public seller;
//    mapping(string => address) public auctionsAddressMap;

    uint256 public feeRate;
    // function initialize() public initializer {
    //     admin = msg.sender;
    // }

    function testHello() public pure returns (string memory) {
        return "Hello, World!";
    }
    // function _authorizeUpgrade(address) internal view override {
    //     require(msg.sender == admin, "Only admin can upgrade");

    // }

}
