// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract NftAction is Initializable, UUPSUpgradeable {


    struct Action {
        address salter;
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
        AggregatorV3Interface public priceETHFeed;

    mapping(address => AggregatorV3Interface) public priceFeeds;
    // constructor() {
    //     admin = msg.sender;
    // }
    function initialize() public initializer {
        admin = msg.sender;
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
        uint256 _nftToken

        ) public {
            require(_duration >= 10, "duration must be greater than 0");
            require(_startPrice > 0, "startPrice must be greater than 0");
        nftActions[nextNftActionId] = Action({
            salter: msg.sender,
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
        require(!nftAction.isEnd && block.timestamp >= nftAction.startTime + nftAction.duration, "nftAction is not end");

        nftAction.isEnd = true;
        // nft转移到最高出价者
        if(nftAction.highestBidder != address(0)) {
            IERC721(nftAction.nftContract).safeTransferFrom(address(this), nftAction.highestBidder, nftAction.nftToken);
        } else {
            // 没有买家，nft转移到卖家
            IERC721(nftAction.nftContract).safeTransferFrom(address(this), nftAction.salter, nftAction.nftToken);
        }

    }

    function getPayValue(address _tokenAddress, uint256 amount) internal view returns (uint) {
         uint payValue;
        if(_tokenAddress == address(0)) {
            amount = msg.value;

            payValue = amount * uint(getChainlinkDataFeedLatestAnswer(address(0)));

        } else {
            payValue = amount * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        }
        return payValue;
    }

    /**
     * 
     ETH 出价 → 因为 ETH 没有合约地址，就统一约定 _tokenAddress == address(0) 来表示「这是原生 ETH 出价」
     */
    // 买家操作
    function placeBid(
        uint256 _nftActionId, 
        uint256 amount,
        address _tokenAddress
        ) public payable {
        Action storage nftAction = nftActions[_nftActionId];

       

        require(!nftAction.isEnd && block.timestamp < nftAction.startTime + nftAction.duration, "nftAction is end");
      
        
        uint payValue = getPayValue(_tokenAddress, amount);
        uint highestBid = getPayValue(nftAction.tokenAddress, nftAction.highestBid);
        uint startPrice = getPayValue(nftAction.tokenAddress, nftAction.startPrice);
        require(payValue > highestBid && payValue >= startPrice, "bid must be greater than highestBid");
        if(_tokenAddress != address(0)) {
            // 检查合约是否有足够的 ERC20 资产
            uint shouldPayValue = getPayValue(_tokenAddress, IERC20(_tokenAddress).balanceOf(address(this)));

            require(shouldPayValue >= payValue, "insufficient balance in current contract");
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), payValue);


        }

        if(nftAction.highestBid > 0) {
            // 判断是否是ERC20资产
            if (_tokenAddress == address(0)) {
                payable(nftAction.highestBidder).transfer(nftAction.highestBid);

            } else {
                IERC20(_tokenAddress).transfer(nftAction.highestBidder, nftAction.highestBid);

            }
        }
        



       

        nftAction.highestBid = msg.value;
        nftAction.highestBidder = msg.sender;
        nftAction.tokenAddress = _tokenAddress;

    }
    function _authorizeUpgrade(address) internal view override {
        // 只有管理员可以升级合约
        require(msg.sender == admin, "Only admin can upgrade");
    }

}