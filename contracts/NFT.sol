// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    // Platform fee structure
    uint256 public platformFee = 250; // e.g., 2.5% fee
    address public feeRecipient;

    // Structs for Listings and Auctions
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    struct Auction {
        address seller;
        uint256 highestBid;
        address highestBidder;
        uint256 startPrice;
        uint256 endTime;
        bool active;
    }

    // Mappings
    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => mapping(uint256 => Auction)) public auctions;
    mapping(uint256 => address) public creators;

    // Events
    event NFTListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );
    event NFTSold(
        address indexed nftContract,
        uint256 indexed tokenId,
        address buyer,
        uint256 price
    );
    event AuctionStarted(
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 startPrice,
        uint256 endTime
    );
    event BidPlaced(
        address indexed nftContract,
        uint256 indexed tokenId,
        address bidder,
        uint256 bid
    );
    event AuctionEnded(
        address indexed nftContract,
        uint256 indexed tokenId,
        address winner,
        uint256 amount
    );

    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
    }

    // Modifiers
    modifier isListed(address nftContract, uint256 tokenId) {
        require(listings[nftContract][tokenId].active, "NFT not listed");
        _;
    }

    modifier isAuctionActive(address nftContract, uint256 tokenId) {
        require(auctions[nftContract][tokenId].active, "Auction not active");
        require(
            block.timestamp < auctions[nftContract][tokenId].endTime,
            "Auction ended"
        );
        _;
    }

    // Platform Fee Management
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    // List an NFT for sale
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        listings[nftContract][tokenId] = Listing(msg.sender, price, true);
        emit NFTListed(nftContract, tokenId, msg.sender, price);
    }

    // Purchase an NFT
    function buyNFT(
        address nftContract,
        uint256 tokenId
    ) external payable isListed(nftContract, tokenId) nonReentrant {
        Listing memory listing = listings[nftContract][tokenId];
        require(msg.value >= listing.price, "Insufficient payment");

        uint256 feeAmount = (msg.value * platformFee) / 10000;
        uint256 sellerAmount = msg.value - feeAmount;

        payable(listing.seller).transfer(sellerAmount);
        payable(feeRecipient).transfer(feeAmount);

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        listings[nftContract][tokenId].active = false;

        emit NFTSold(nftContract, tokenId, msg.sender, msg.value);
    }

    // Cancel listing
    function cancelListing(
        address nftContract,
        uint256 tokenId
    ) external isListed(nftContract, tokenId) {
        Listing memory listing = listings[nftContract][tokenId];
        require(msg.sender == listing.seller, "Only seller can cancel listing");

        IERC721(nftContract).transferFrom(
            address(this),
            listing.seller,
            tokenId
        );
        listings[nftContract][tokenId].active = false;
    }

    // Start an auction
    function startAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 duration
    ) external {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not owner"
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        uint256 endTime = block.timestamp + duration;
        auctions[nftContract][tokenId] = Auction(
            msg.sender,
            0,
            address(0),
            startPrice,
            endTime,
            true
        );

        emit AuctionStarted(
            nftContract,
            tokenId,
            msg.sender,
            startPrice,
            endTime
        );
    }

    // Place a bid on an auction
    function placeBid(
        address nftContract,
        uint256 tokenId
    ) external payable isAuctionActive(nftContract, tokenId) nonReentrant {
        Auction storage auction = auctions[nftContract][tokenId];
        require(msg.value > auction.highestBid, "Bid too low");

        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(nftContract, tokenId, msg.sender, msg.value);
    }

    // End an auction
    function endAuction(
        address nftContract,
        uint256 tokenId
    ) external isAuctionActive(nftContract, tokenId) nonReentrant {
        Auction storage auction = auctions[nftContract][tokenId];
        require(block.timestamp >= auction.endTime, "Auction still active");

        auction.active = false;
        uint256 feeAmount = (auction.highestBid * platformFee) / 10000;
        uint256 sellerAmount = auction.highestBid - feeAmount;

        if (auction.highestBidder != address(0)) {
            payable(auction.seller).transfer(sellerAmount);
            payable(feeRecipient).transfer(feeAmount);
            IERC721(nftContract).transferFrom(
                address(this),
                auction.highestBidder,
                tokenId
            );

            emit AuctionEnded(
                nftContract,
                tokenId,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            // No bids were placed, return NFT to the seller
            IERC721(nftContract).transferFrom(
                address(this),
                auction.seller,
                tokenId
            );
        }
    }
}
