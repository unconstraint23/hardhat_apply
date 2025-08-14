// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

contract NftAction {

    struct NftAction {
        address salter;
        uint256 duration;
        uint256 startPrice;
        
        uint256 startTime;
        bool isEnd;
        // 最高出价
        uint256 highestBid;
        // 最高出价者

        address highestBidder;

        address nftContract;
        // nft token id 合约地址
        uint256 nftToken;


    }
    mapping(uint256 => NftAction) public nftActions;
    uint256 public nextNftActionId;
    address public admin;
    constructor() {
        admin = msg.sender;
    }
    // 创建卖品
    function createNftAction(
        uint256 _duration, 
        uint256 _startPrice,
        address _nftContract,
        uint256 _nftToken

        ) public {
            require(_duration > 1000 * 60, "duration must be greater than 0");
            require(_startPrice > 0, "startPrice must be greater than 0");
        nftActions[nextNftActionId] = NftAction({
            salter: msg.sender,
            duration: _duration,
            startPrice: _startPrice,
            startTime: block.timestamp,
            isEnd: false,
            highestBid: 0,
            highestBidder: address(0),
            nftContract: _nftContract,
            nftToken: _nftToken
        });
        nextNftActionId++;
    }
    // 买家操作
    function placeBid(uint256 _nftActionId) public payable {
        NftAction storage nftAction = nftActions[_nftActionId];
        require(!nftAction.isEnd && block.timestamp < nftAction.startTime + nftAction.duration, "nftAction is end");

        require(msg.value > nftAction.highestBid && msg.value >= nftAction.startPrice, "bid must be greater than highestBid");
        if(nftAction.highestBidder != address(0)) {
            payable(nftAction.highestBidder).transfer(nftAction.highestBid);
        }

        nftAction.highestBid = msg.value;
        nftAction.highestBidder = msg.sender;
    }


}