// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //security 

contract NFTMarket is ReentrancyGuard{ //inhereting for reentrancyguard
    using Counters for Counters.Counter; 
    Counters.Counter private _itemIds; // for items created
    Counters.Counter private _itemsSold; // for items sold

    address payable owner; 
    uint256 listingPrice = 0.025 ether; //how much it charges the contracts to be used as a fee (on matic, not ether)

    constructor(){
        owner = payable(msg.sender); //the owner of the contracts is who deploy it
    }

    struct MarketItem{ //and object or a map (it holds other values)
        uint itemId; // id of the item
        address nftContract; //contract address
        uint256 tokenId;
        address payable seller;
        address payable owner; 
        uint256 price; 
        bool sold; //if it has been sold or not
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256){ //to know the listing price
        return listingPrice;
    }

    function createMarketItem( //for creating a market item
        address nftContract,
        uint256 tokenId,
        uint256 price
     ) public payable nonReentrant{ //to prevent a reentry attack
        require(price> 0, "price must be at least 1"); // not allowing users to list something for free
        require(msg.value == listingPrice, "Price must be equal to listing price");
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); // transfering the ownership of the token to the contract

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );   
    }

    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant{
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        require(msg.value == price, "Submit the asking price in order to complete the purchase");
        
        idToMarketItem[itemId].seller.transfer(msg.value); //transfering the money to the seller
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId); //transfering the token ownership from the contract address to the buyer 
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true; //changing the "sold boolean" to true
        _itemsSold.increment(); 
        payable(owner).transfer(listingPrice);
        }

    function fetchMarketItems() public view returns (MarketItem[] memory){
        uint itemCount = _itemIds.current(); // how many items were created
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current(); // how many items are still avaiable (not sold)
        uint currentIndex = 0;


        MarketItem[] memory items = new MarketItem[] (unsoldItemCount);
        for (uint i=0; i<itemCount; i++){
            if (idToMarketItem[i +1].owner == address(0)){
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }    

    function fetchMyNFTs() public view returns (MarketItem[] memory) { //to know my nfts
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i<totalItemCount; i++){
            if (idToMarketItem[i+1].owner == msg.sender){
                itemCount +=1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++){
            if (idToMarketItem[i + 1].owner == msg.sender){
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }      
        return items; 
    }
    function fetchItemsCreated() public view returns (MarketItem[] memory) { // returning an array of items created by the user
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    
    for (uint i=0; i< totalItemCount; i++){
        if (idToMarketItem[i + 1].seller== msg.sender){
            itemCount += 1;
        }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i<totalItemCount; i++){
        if (idToMarketItem[i + 1].seller == msg.sender){
            uint currentId = idToMarketItem[i + 1].itemId;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items [currentIndex] = currentItem;
            currentIndex += 1;
        }
    }
    return items;
    }
}