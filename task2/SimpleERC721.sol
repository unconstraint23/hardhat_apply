// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract SimpleERC721 is ERC721URIStorage {
    
    uint256 public tokenCounter;

    constructor() ERC721("SimpleERC721", "S721") {
        tokenCounter = 0;
    }

    function mintNFT(address recipient, string memory tokenURI) public returns (uint256) {
        uint256 tokenId = ++tokenCounter;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }
}
