// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";



contract NftActionSingle is IERC721Receiver {
    struct Action {
        address seller;
        address nftContract;
        uint256 nftToken;
        uint256 startPrice;
        uint256 highestBid;
        address highestBidder;
        address tokenAddress;
        uint256 duration;
        uint256 startTime;
        bool isEnd;
    }

    Action public action;

    address public feeRecipient;
    uint256 public feeRate;

    event BidPlaced(address bidder, uint256 amount, address token);
    event AuctionEnded(address winner, uint256 highestBid, address token);

    constructor(
        address _seller,
        address _nftContract,
        uint256 _nftToken,
        uint256 _startPrice,
        uint256 _duration,
        address _feeRecipient,
        uint256 _feeRate
    ) {
        action.seller = _seller;
        action.nftContract = _nftContract;
        action.nftToken = _nftToken;
        action.startPrice = _startPrice;
        action.duration = _duration;
        action.startTime = block.timestamp;

        feeRecipient = _feeRecipient;
        feeRate = _feeRate;

        IERC721(_nftContract).transferFrom(_seller, address(this), _nftToken);
    }

    // 普通出价
    function placeBid(uint256 amount, address _tokenAddress) public payable {
        require(!action.isEnd, "Auction ended");
        require(block.timestamp < action.startTime + action.duration, "Auction expired");

        uint256 bidAmount = (_tokenAddress == address(0)) ? msg.value : amount;
        require(bidAmount > action.highestBid && bidAmount >= action.startPrice, "Bid too low");

        // 退还上一位出价者
        if (action.highestBid > 0) {
            if (action.tokenAddress == address(0)) {
                payable(action.highestBidder).transfer(action.highestBid);
            } else {
                IERC20(action.tokenAddress).transfer(action.highestBidder, action.highestBid);
            }
        }

        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        }

        action.highestBid = bidAmount;
        action.highestBidder = msg.sender;
        action.tokenAddress = _tokenAddress;

        emit BidPlaced(msg.sender, bidAmount, _tokenAddress);
    }

    // 跨链出价模拟
    function receiveCrossChainBid(
        uint256 amount,
        address _tokenAddress,
        address _buyer
    ) public payable {
        console.log("Cross-chain bid received:", _buyer, amount, _tokenAddress);

        uint256 bidAmount = (_tokenAddress == address(0)) ? msg.value : amount;
        require(bidAmount > action.highestBid && bidAmount >= action.startPrice, "Bid too low");

        // 退还上一位出价者
        if (action.highestBid > 0) {
            if (action.tokenAddress == address(0)) {
                payable(action.highestBidder).transfer(action.highestBid);
            } else {
                IERC20(action.tokenAddress).transfer(action.highestBidder, action.highestBid);
            }
        }

        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).transferFrom(_buyer, address(this), amount);
        }

        action.highestBid = bidAmount;
        action.highestBidder = _buyer;
        action.tokenAddress = _tokenAddress;

        emit BidPlaced(_buyer, bidAmount, _tokenAddress);
    }

    function endAuction() public {
        require(!action.isEnd, "Already ended");
        require(block.timestamp >= action.startTime + action.duration, "Auction not ended");

        action.isEnd = true;

        uint256 fee = (action.highestBid * feeRate) / 100;
        uint256 payValue = action.highestBid - fee;

        if (action.highestBidder != address(0)) {
            IERC721(action.nftContract).transferFrom(address(this), action.highestBidder, action.nftToken);

            if (action.tokenAddress == address(0)) {
                payable(feeRecipient).transfer(fee);
                payable(action.seller).transfer(payValue);
            } else {
                IERC20(action.tokenAddress).transfer(feeRecipient, fee);
                IERC20(action.tokenAddress).transfer(action.seller, payValue);
            }

            emit AuctionEnded(action.highestBidder, action.highestBid, action.tokenAddress);
        } else {
            IERC721(action.nftContract).transferFrom(address(this), action.seller, action.nftToken);
        }
    }

     function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
