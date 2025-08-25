// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";



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
    mapping(address => AggregatorV3Interface) public priceFeeds;
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
        action.isEnd = false;
        action.tokenAddress = address(0);
        action.highestBid = 0;
        action.highestBidder = address(0);
        feeRecipient = _feeRecipient;
        feeRate = _feeRate;

   
    }

// 相当于记录不同货币的汇率
    function setPriceFeeds(address _tokenAddress, address _priceAddr) public {
        priceFeeds[_tokenAddress] = AggregatorV3Interface(_priceAddr);
    }
     function getChainlinkDataFeedLatestAnswer(address _tokenAddress) public view returns (int) {
        AggregatorV3Interface priceFeed = priceFeeds[_tokenAddress];
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return answer;
    }

     /**
     * 
     ETH 出价 → 因为 ETH 没有合约地址，就统一约定 _tokenAddress == address(0) 来表示「这是原生 ETH 出价」
     */
    // 买家操作
    function placeBidForEth(
        uint256 _nftActionId, 
        uint256 amount,
        address _tokenAddress
        ) public payable {

       amount = msg.value;

        require(!action.isEnd && block.timestamp < action.startTime + action.duration, "nftAction is end");
      
        
        require(amount > action.highestBid && amount >= action.startPrice, "bid must be greater than highestBid");
        


        

        if(action.highestBid > 0) {
            payable(action.highestBidder).transfer(action.highestBid);
        }
        



       

        action.highestBid = msg.value;
        action.highestBidder = msg.sender;
        action.tokenAddress = _tokenAddress;

    }
     function getPayValue(address _tokenAddress, uint256 amount) internal view returns (uint) {
             AggregatorV3Interface  feedAddress = priceFeeds[_tokenAddress];  
            uint8 decimals = feedAddress.decimals();
             int256 price = getChainlinkDataFeedLatestAnswer(_tokenAddress);
            uint256 adjustedPrice = uint256(price) * 1e8;
        
        return amount * adjustedPrice / 1e8;
    }

    // 普通出价
    function placeBid(uint256 amount, address _tokenAddress) public payable {
        

        require(!action.isEnd && block.timestamp < action.startTime + action.duration, "nftAction is end");
      
        console.log('_tokenAddress:', _tokenAddress, "highestBidder", action.highestBidder);
        console.log("highestBid:", action.highestBid);   
        uint payValue;
        if(_tokenAddress == address(0)) {
            payValue = getPayValue(_tokenAddress, msg.value);
        } else {
            payValue = getPayValue(_tokenAddress, amount);

        }

        uint highestBid = getPayValue(action.tokenAddress, action.highestBid);
        uint startPrice = getPayValue(action.tokenAddress, action.startPrice);
        console.log('payValue:', payValue, 'highestBid:', highestBid);
        console.log("pay:", payValue > highestBid);

        require(payValue > highestBid && payValue >= startPrice, "bid must be greater than highestBid");
        if(_tokenAddress != address(0)) {
            // 检查合约是否有足够的 ERC20 资产
            
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);


        }

        if(action.highestBid > 0) {
            // 判断是否是ERC20资产
            if (_tokenAddress == address(0)) {
                payable(action.highestBidder).transfer(action.highestBid);

            } else {
                IERC20(_tokenAddress).transfer(action.highestBidder, action.highestBid);

            }
        }
        



       
        if(_tokenAddress == address(0)) {
            action.highestBid = msg.value;
        } else {
            action.highestBid = amount;
        }
        action.highestBidder = msg.sender;
        action.tokenAddress = _tokenAddress;

        emit BidPlaced(msg.sender, amount, _tokenAddress);
    }

    // 跨链出价模拟
    // function receiveCrossChainBid(
    //     uint256 amount,
    //     address _tokenAddress,
    //     address _buyer
    // ) public payable {
    //     console.log("Cross-chain bid received:", _buyer, amount, _tokenAddress);

    //     uint256 bidAmount = (_tokenAddress == address(0)) ? msg.value : amount;
    //     require(bidAmount > action.highestBid && bidAmount >= action.startPrice, "Bid too low");

    //     // 退还上一位出价者
    //     if (action.highestBid > 0) {
    //         if (action.tokenAddress == address(0)) {
    //             payable(action.highestBidder).transfer(action.highestBid);
    //         } else {
    //             IERC20(action.tokenAddress).transfer(action.highestBidder, action.highestBid);
    //         }
    //     }

    //     if (_tokenAddress != address(0)) {
    //         IERC20(_tokenAddress).transferFrom(_buyer, address(this), amount);
    //     }

    //     action.highestBid = bidAmount;
    //     action.highestBidder = _buyer;
    //     action.tokenAddress = _tokenAddress;

    //     emit BidPlaced(_buyer, bidAmount, _tokenAddress);
    // }

    function endAuction() public {
         console.log(
            "endAuction",
            action.startTime,
            action.duration,
            block.timestamp

        );
        console.log('action.highestBid:', action.highestBid, action.highestBidder);

        require(!action.isEnd && block.timestamp >= action.startTime + action.duration, "nftAction is not end");

        action.isEnd = true;
       
        // nft转移到最高出价者
        if(action.highestBidder != address(0)) {
            uint256 fee = (action.highestBid * feeRate) / 100;
            uint256 payValue = IERC20(action.tokenAddress).balanceOf(address(this)) - fee;
            console.log('fee:', fee, 'payValue:', payValue);
            console.log("tokenAddress", action.tokenAddress);

            IERC721(action.nftContract).safeTransferFrom(address(this), action.highestBidder, action.nftToken);
            if(action.tokenAddress == address(0)) {
                // eth支付
                payable(feeRecipient).transfer(fee);
                payable(action.seller).transfer(payValue);

            } else {
                console.log("contract balance:", IERC20(action.tokenAddress).balanceOf(address(this)));
                // IERC20支付
                IERC20(action.tokenAddress).transfer(feeRecipient, fee);
                IERC20(action.tokenAddress).transfer(action.seller, payValue);
                console.log("seller balance:", IERC20(action.tokenAddress).balanceOf(action.seller));
                console.log("feeRecipient balance:", IERC20(action.tokenAddress).balanceOf(feeRecipient)); 
                console.log("seller address", action.seller);
                console.log("feeRecipient address", feeRecipient);

            }
        } else {

            // 没有买家，nft转移到卖家
            IERC721(action.nftContract).safeTransferFrom(address(this), action.seller, action.nftToken);
        }
    }
    function getHighestBidder() external view returns (address) {
    return action.highestBidder;
}

     function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
