// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NftActionOfFactoryV2 is Initializable {
address public admin;
    address public feeRecipient;
    address public seller;

    uint256 public nextNftActionId;
   
    function initialize(address _feeRecipient, address _seller) public initializer {

        admin = msg.sender;
        feeRecipient = _feeRecipient;
        seller = _seller;
    }

    

}