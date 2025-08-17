// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract TestERC20 is IERC20 {
   /**
    记录：（前提条件：A用户账户上假设有100余额）
    1、当A 用户授权B用户50余额时，需不需要同时给B用户转账50的余额？
    2、当A 用户授权其他用户之前是否要查看当前剩余可授权额度？
   */
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;
     address immutable owner;
    constructor() {
        owner = msg.sender;
    }
     modifier onlyOwner {
        require(msg.sender == owner, "only owner can call");
        _;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount > 0 ,"amount must be more than 0");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function mint(uint256 amount) external onlyOwner {
        _balances[msg.sender] += amount;
    }
    function totalSupply() external view returns (uint256) {
        return _balances[msg.sender];
    }
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(amount > 0, "amount must be more than 0");
        require(_allowances[msg.sender][from] >= amount, "exceeds approved amount");
        require(_balances[from] >= amount, "Insufficient balance");
        _allowances[msg.sender][from] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;    
    }    
}
