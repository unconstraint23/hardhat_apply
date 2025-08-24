// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "hardhat/console.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract NftAction is Initializable, UUPSUpgradeable, IERC721Receiver {


    event RecordBalances(address seller, uint256 sellerBalance, address feeRecipient, uint256 fee);

    struct Action {
        address seller;
        uint256 duration;
        uint256 startPrice;
        
        uint256 startTime;
        bool isEnd;
        // 最高出价
        uint256 highestBid;
        // 最高出价者

        address highestBidder;
        // 合约地址
        address nftContract;
        // nft token id 
        uint256 nftToken;
        // 支付token地址
        address tokenAddress;


    }
    mapping(uint256 => Action) public nftActions;
    uint256 public nextNftActionId;
    address public admin;
    address public seller;
     address public feeRecipient;
    uint256 public feeRate;
    AggregatorV3Interface public priceETHFeed;

    mapping(address => AggregatorV3Interface) public priceFeeds;
    // constructor() {
    //     admin = msg.sender;
    // }
    function initialize(address _feeRecipient,address _seller) public initializer {
        admin = msg.sender;
        seller = _seller;
        feeRecipient = _feeRecipient;
        feeRate = 10;

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
    // 创建卖品
    function createNftAction(
        uint256 _duration, 
        uint256 _startPrice,
        address _nftContract,
        uint256 _nftToken,
        address _sellerAddress
        ) public {
            require(msg.sender == admin, "Only admin can create auctions");
            require(_duration >= 10, "duration must be greater than 0");
            require(_startPrice > 0, "startPrice must be greater than 0");
            IERC721(_nftContract).safeTransferFrom(seller, address(this), _nftToken);
        nftActions[nextNftActionId] = Action({
            seller: _sellerAddress,
            duration: _duration,
            startPrice: _startPrice,
            startTime: block.timestamp,
            isEnd: false,
            highestBid: 0,
            highestBidder: address(0),
            nftContract: _nftContract,
            nftToken: _nftToken,
            tokenAddress: address(0)

        });
        nextNftActionId++;
    }

    function endNftAction(uint256 _nftActionId) external {
        Action storage nftAction = nftActions[_nftActionId];
      
         console.log(
            "endAuction",
            nftAction.startTime,
            nftAction.duration,
            block.timestamp

        );
        console.log('nftAction.highestBid:', nftAction.highestBid, nftAction.highestBidder);

        require(!nftAction.isEnd && block.timestamp >= nftAction.startTime + nftAction.duration, "nftAction is not end");

        nftAction.isEnd = true;
       
        // nft转移到最高出价者
        if(nftAction.highestBidder != address(0)) {
            uint256 fee = (nftAction.highestBid * feeRate) / 100;
            uint256 payValue = IERC20(nftAction.tokenAddress).balanceOf(address(this)) - fee;
            console.log('fee:', fee, 'payValue:', payValue);
            console.log("tokenAddress", nftAction.tokenAddress);

            IERC721(nftAction.nftContract).safeTransferFrom(address(this), nftAction.highestBidder, nftAction.nftToken);
            if(nftAction.tokenAddress == address(0)) {
                // eth支付
                payable(feeRecipient).transfer(fee);
                payable(nftAction.seller).transfer(payValue);

            } else {
                console.log("contract balance:", IERC20(nftAction.tokenAddress).balanceOf(address(this)));
                // IERC20支付
                IERC20(nftAction.tokenAddress).transfer(feeRecipient, fee);
                IERC20(nftAction.tokenAddress).transfer(nftAction.seller, payValue);
                emit RecordBalances(nftAction.seller, IERC20(nftAction.tokenAddress).balanceOf(nftAction.seller), feeRecipient, fee);
                console.log("seller balance:", IERC20(nftAction.tokenAddress).balanceOf(nftAction.seller));
                console.log("feeRecipient balance:", IERC20(nftAction.tokenAddress).balanceOf(feeRecipient)); 
                console.log("seller address", nftAction.seller);
                console.log("feeRecipient address", feeRecipient);

            }
        } else {

            // 没有买家，nft转移到卖家
            IERC721(nftAction.nftContract).safeTransferFrom(address(this), nftAction.seller, nftAction.nftToken);
        }

    }

    function getPayValue(address _tokenAddress, uint256 amount) internal view returns (uint) {
             AggregatorV3Interface  feedAddress = priceFeeds[_tokenAddress];  
            uint8 decimals = feedAddress.decimals();
             int256 price = getChainlinkDataFeedLatestAnswer(_tokenAddress);
            uint256 adjustedPrice = uint256(price) * 1e8;
        
        return amount * adjustedPrice / 1e8;
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
        Action storage nftAction = nftActions[_nftActionId];

       amount = msg.value;

        require(!nftAction.isEnd && block.timestamp < nftAction.startTime + nftAction.duration, "nftAction is end");
      
        
        require(amount > nftAction.highestBid && amount >= nftAction.startPrice, "bid must be greater than highestBid");
        


        

        if(nftAction.highestBid > 0) {
            payable(nftAction.highestBidder).transfer(nftAction.highestBid);
        }
        



       

        nftAction.highestBid = msg.value;
        nftAction.highestBidder = msg.sender;
        nftAction.tokenAddress = _tokenAddress;

    }
    // CCIP 回调模拟：跨链出价
    function receiveCrossChainBid(
        uint256 actionId,
        uint256 amount,
        address _tokenAddress,
        address _buyerAddress
    ) public payable returns (bool) {
     
        console.log("_tokenAddress:", _tokenAddress, msg.value, amount);
        Action storage nftAction = nftActions[actionId];
        require(!nftAction.isEnd, "Auction ended");
        require(amount > nftAction.highestBid, "Bid too low");

         uint payValue;
        if(_tokenAddress == address(0)) {
            payValue = getPayValue(_tokenAddress, msg.value);
        } else {
            payValue = getPayValue(_tokenAddress, amount);

        }

        uint highestBid = getPayValue(nftAction.tokenAddress, nftAction.highestBid);
        uint startPrice = getPayValue(nftAction.tokenAddress, nftAction.startPrice);
        console.log('218payValue:', payValue, '218highestBid:', highestBid);
      

        require(payValue > highestBid && payValue >= startPrice, "bid must be greater than highestBid in ccip");
        if(_tokenAddress != address(0)) {
            // 检查合约是否有足够的 ERC20 资产
            
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);


        }

        if(nftAction.highestBid > 0) {
            // 判断是否是ERC20资产
            if (_tokenAddress == address(0)) {
                payable(nftAction.highestBidder).transfer(nftAction.highestBid);

            } else {
                IERC20(_tokenAddress).transfer(nftAction.highestBidder, nftAction.highestBid);

            }
        }
        



       
        if(_tokenAddress == address(0)) {
            nftAction.highestBid = msg.value;
        } else {
            nftAction.highestBid = amount;
        }
        nftAction.highestBidder = _buyerAddress;
        nftAction.tokenAddress = _tokenAddress;
        return true;
    }

 function placeBid(
        uint256 _nftActionId, 
        uint256 amount,
        address _tokenAddress
        ) public payable {
        Action storage nftAction = nftActions[_nftActionId];

       

        require(!nftAction.isEnd && block.timestamp < nftAction.startTime + nftAction.duration, "nftAction is end");
      
        console.log('_tokenAddress:', _tokenAddress, "highestBidder", nftAction.highestBidder);
        console.log("267highestBid:", nftAction.highestBid);
        uint payValue;
        if(_tokenAddress == address(0)) {
            payValue = getPayValue(_tokenAddress, msg.value);
        } else {
            payValue = getPayValue(_tokenAddress, amount);

        }

        uint highestBid = getPayValue(nftAction.tokenAddress, nftAction.highestBid);
        uint startPrice = getPayValue(nftAction.tokenAddress, nftAction.startPrice);
        // console.log('payValue:', payValue, 'highestBid:', highestBid);
        // console.log("pay:", payValue > highestBid);

        require(payValue > highestBid && payValue >= startPrice, "bid must be greater than highestBid");
        if(_tokenAddress != address(0)) {
            // 检查合约是否有足够的 ERC20 资产
            
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);


        }

        if(nftAction.highestBid > 0) {
            // 判断是否是ERC20资产
            if (_tokenAddress == address(0)) {
                payable(nftAction.highestBidder).transfer(nftAction.highestBid);

            } else {
                IERC20(_tokenAddress).transfer(nftAction.highestBidder, nftAction.highestBid);

            }
        }
        



       
        if(_tokenAddress == address(0)) {
            nftAction.highestBid = msg.value;
        } else {
            nftAction.highestBid = amount;
        }
        nftAction.highestBidder = msg.sender;
        nftAction.tokenAddress = _tokenAddress;
       
    }

    function _authorizeUpgrade(address) internal view override {
        // 只有管理员可以升级合约
        require(msg.sender == admin, "Only admin can upgrade");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}