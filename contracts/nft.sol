// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; //erc 721 standard
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; //allow us to use the set token uri function
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage{ 
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; //incrementing token IDS
    address contractAddress; //address of the marketplace

    constructor(address marketplaceAddress) ERC721("Cambalache tokens", "CAMB"){
        contractAddress = marketplaceAddress;
    }

    function createToken(string memory tokenURI) public returns (uint){ //for minting new tokens
        _tokenIds.increment(); //incrementing tokens ID
        uint256 newItemId = _tokenIds.current(); //this variable get the current token ID number
        _mint(msg.sender, newItemId); // mint the token, msg sender as the creator and token ID as the current ID number
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true); // giving the aproval to transact the token between users
        return newItemId;
    }
}