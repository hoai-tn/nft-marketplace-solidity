// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract CTCKMarketplace is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIds;
    uint256 private _quantitySold; // keep the track how many tokens are getting sold

    uint256 private _listingPrice = 0.0015 ether;

    mapping(uint256 => MarketItem) private _idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    event MarketItemCreated(
        uint indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor(
        address initialOwner
    ) ERC721("CTCK Marketplace", "CTCKM") Ownable(initialOwner) {}

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

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(
            msg.value == _listingPrice,
            "Price must be equal to listing price"
        );
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

    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(
            _idMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform operation"
        );
        require(
            msg.value == _listingPrice,
            "Price must be equal to listing price"
        );

        _idMarketItem[tokenId].owner = payable(address(this));
        _idMarketItem[tokenId].seller = payable(msg.sender);
        _idMarketItem[tokenId].price = price;
        _idMarketItem[tokenId].sold = false;

        _quantitySold += 1;

        _transfer(msg.sender, address(this), tokenId);
    }

    // buy market nft
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = _idMarketItem[tokenId].price;
        require(
            msg.value == price,
            "Please submit asking price in order to complete the purchase"
        );
        _idMarketItem[tokenId].owner = payable(address(this));
        _idMarketItem[tokenId].seller = payable(msg.sender);
        _idMarketItem[tokenId].sold = true;

        _transfer(address(this), msg.sender, tokenId);

        (bool sentToOwner, ) = owner().call{value: _listingPrice}("");
        require(sentToOwner, "Failed to send Ether to Owner");

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
