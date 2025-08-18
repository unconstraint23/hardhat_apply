// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestERC721 is ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;
    mapping(uint256 => string) private _tokenURIs;
    constructor() ERC721("TestERC721", "TERC721") Ownable(msg.sender) {
        
    }


    
      function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    ///  查询 token 的元数据 URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // 用 ownerOf 判断是否存在
        address owner = ownerOf(tokenId);
        require(owner != address(0), "Token does not exist");

        return _tokenURIs[tokenId];
    }
}