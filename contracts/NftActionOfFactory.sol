// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./NftActionSingle.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NftActionOfFactory is Initializable, UUPSUpgradeable {


    address public admin;
    address public feeRecipient;
    address public seller;
   mapping(string => address) public auctionsAddressMap;


    event NewAuction(address indexed auction, address indexed seller, address nftContract, uint256 tokenId);

    function initialize(address _feeRecipient, address _seller) public initializer {
        admin = msg.sender;
        feeRecipient = _feeRecipient;
        seller = _seller;

    }

    function createNftAction(
        string calldata _auctionId,
        uint256 duration,
        uint256 startPrice,
        address nftContract,
        uint256 nftToken,
        address _seller

    ) external {
        require(auctionsAddressMap[_auctionId] == address(0), "Auction already exists");

        // 部署新的拍卖合约
        NftActionSingle auction = new NftActionSingle(
            _seller,
            nftContract,
            nftToken,
            startPrice,
            duration,
            feeRecipient,
            10
        );

        auctionsAddressMap[_auctionId] = address(auction);
             IERC721(nftContract).safeTransferFrom(_seller, address(auction), nftToken);
        emit NewAuction(address(auction), _seller, nftContract, nftToken);
    }

    function getAuctionAddress(string calldata _auctionId) external view returns(address) {
        return auctionsAddressMap[_auctionId];
    }
   
    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == admin, "Not admin");

    }


}
