// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NMTMarketplace is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIds;
    uint256 private _itemsSold; // keep the track how many tokens are getting Sold

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

    modifier priceMustBeGreaterThanZero(uint256 price) {
        require(price > 0, "Price must be greater than 0");
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

    function _createMarketItem(
        uint256 tokenId,
        uint256 price
    ) private isEqualListingPrice(msg.value) priceMustBeGreaterThanZero(price) {
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

    function reSellToken(
        uint256 tokenId,
        uint256 price
    )
        public
        payable
        isEqualListingPrice(price)
        priceMustBeGreaterThanZero(price)
    {
        require(
            _idMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform operation"
        );

        _idMarketItem[tokenId].owner = payable(address(this));
        _idMarketItem[tokenId].seller = payable(msg.sender);
        _idMarketItem[tokenId].price = price;
        _idMarketItem[tokenId].isSold = false;

        _itemsSold--;

        _transfer(msg.sender, address(this), tokenId);
    }

    /// Buy NFT
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = _idMarketItem[tokenId].price;
        require(
            msg.value == price,
            "Please submit asking price in order to complete the purchase"
        );
        _idMarketItem[tokenId].owner = payable(address(0));
        _idMarketItem[tokenId].seller = payable(msg.sender);
        _idMarketItem[tokenId].isSold = true;
        _itemsSold++;

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
    // Fetch unsold NFTs
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds;
        uint256 unsoldItemCount = _itemsSold;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](
            itemCount - unsoldItemCount
        );

        for (uint256 i = 0; i < itemCount; i++) {
            if (_idMarketItem[i + 1].owner == address(this)) {
                items[currentIndex] = _idMarketItem[i + 1];
                currentIndex++;
            }
        }
        return items;
    }

    // Fetch NFTs that the user has purchased
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_idMarketItem[i + 1].owner == msg.sender) {
                items[currentIndex] = _idMarketItem[i + 1];
                currentIndex++;
            }
        }
        return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_idMarketItem[i + 1].owner == address(this)) {
                items[currentIndex] = _idMarketItem[i + 1];
                currentIndex++;
            }
        }
        return items;
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
