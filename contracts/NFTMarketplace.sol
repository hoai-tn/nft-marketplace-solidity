// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NFTMarketplace is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIds;
    uint256 private _quantitySold; // keep the track how many tokens are getting Sold

    uint256 private _listingPrice = 0.0015 ether;

    mapping(uint256 => MarketItem) private _idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool isSold;
    }
    
    event MarketItemCreated(
        uint indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool isSold
    );

    constructor(
        address initialOwner
    ) ERC721("Nart Meta Token", "NMNFT") Ownable(initialOwner) {}
    // must be equal to listing price

    modifier isEqualListingPrice(uint256 price) {
        require(price == _listingPrice, "Price must be equal to listing price");
        _;
    }

    function updateListingPrice(uint256 listingPrice) public payable onlyOwner {
        _listingPrice = listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return _listingPrice;
    }

    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        _tokenIds += 1;
        uint256 newTokenId = _tokenIds;
        
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _createMarketItem(newTokenId, price);

        return newTokenId;
    }

    function _createMarketItem(uint256 tokenId, uint256 price) private isEqualListingPrice(price) {
        // MarketItem newMarketItem =      MarketItem(tokenId, );

        _idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }
    
    function reSellToken(uint256 tokenId, uint256 price) public payable isEqualListingPrice(price) {
        require(
            _idMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform operation"
        );

        _idMarketItem[tokenId].owner = payable(address(this));
        _idMarketItem[tokenId].seller = payable(msg.sender);
        _idMarketItem[tokenId].price = price;
        _idMarketItem[tokenId].isSold = false;

        _quantitySold += 1;

        _transfer(msg.sender, address(this), tokenId);
    }

   /// Buy NFT
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = _idMarketItem[tokenId].price;
        require(
            msg.value == price,
            "Please submit asking price in order to complete the purchase"
        );
        _idMarketItem[tokenId].owner = payable(address(this));
        _idMarketItem[tokenId].seller = payable(msg.sender);
        _idMarketItem[tokenId].isSold = true;

        _transfer(address(this), msg.sender, tokenId);
        
        // send ether _listingPrice to owner
        (bool sentToOwner, ) = owner().call{value: _listingPrice}("");
        require(sentToOwner, "Failed to send Ether to Owner");

        // send ether msg.value to seller
        (bool sentToSeller, ) = _idMarketItem[tokenId].seller.call{
            value: msg.value
        }("");
        require(sentToSeller, "Failed to send Ether to Seller");
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
