// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./NftActionSingle.sol";
import "hardhat/console.sol";

contract NftActionFactory is Initializable {

    address public admin;
    address public feeRecipient;
    uint256 public feeRate;
    address public seller;
    address[] public allAuctions;

    event NewAuction(address indexed auction, address indexed seller, address nftContract, uint256 tokenId);

    function initialize(address _feeRecipient, address _seller) public initializer {
        admin = msg.sender;
        feeRecipient = _feeRecipient;
        feeRate = 10;
        seller = _seller;

    }

    function createNftAction(
        address _seller,
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 duration
    ) external returns(address) {
        // 部署新的拍卖合约
        NftActionSingle auction = new NftActionSingle(
            _seller,
            nftContract,
            tokenId,
            startPrice,
            duration,
            feeRecipient,
            feeRate
        );

        allAuctions.push(address(auction));

        emit NewAuction(address(auction), seller, nftContract, tokenId);
        return address(auction);
    }

    function getAllAuctions() external view returns(address[] memory) {
        return allAuctions;
    }
}
