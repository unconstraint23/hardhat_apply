// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


contract BeggingContract {
    event Donate(address indexed sender, uint256 amount);
    event DrawLog(bytes output);
    mapping (address account => uint256 amount) public begCount; 
    uint256 startTime = block.timestamp;
    uint256 duration = 1000 * 100;
    address immutable owner;
    constructor() {
        owner = msg.sender;
    }
    modifier overTimer {
        require(block.timestamp < startTime + duration, "is end");
        _;
    }

     modifier onlyOwner {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    function donate() external payable overTimer {
       begCount[msg.sender] += msg.value;
       emit Donate(msg.sender, msg.value);

    }

    function getDonate(address account) external view returns (uint256) {

        return begCount[account];
    }

    function withDraw() external payable onlyOwner {
        require(address(this).balance > 0, "no money to withdraw");
        (bool success, bytes memory data) = payable(msg.sender).call{value: address(this).balance}("");
            require(success, "Call failed");
        emit DrawLog(data);
    }

}