// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract NFTMarketplace is Ownable, ReentrancyGuard {
    IERC721 public nftContract;

    struct Listing {
        uint256 price;
        address seller;
        uint256 endTime;
        bool isAuction;
    }

    struct Offer {
        uint256 amount;
        address offerer;
    }

    mapping(uint256 => Offer[]) public nftOffers;

    uint256 public constant OPEN_SEA_FEE = 25; // 2.5% fee in basis points (100 basis points = 1%)

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => mapping(uint256 => address)) public highestBidders;
    mapping(address => mapping(uint256 => uint256)) public highestBids;

    // Royalties 103.2749975971
    //96.99995744
    
    event NFTListed(address indexed nftContract, uint256 indexed tokenId, uint256 price, uint256 endTime, bool isAuction, address indexed seller);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed buyer);
    event NFTListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event NFTBidPlaced(address indexed nftContract, uint256 indexed tokenId, uint256 bidAmount, address indexed bidder);
    event OfferMade(uint256 indexed tokenId, uint256 amount, address indexed offerer);
    event OfferAccepted(uint256 indexed tokenId, uint256 amount, address indexed offerer, address indexed seller);

    constructor(address _nftContract) Ownable(msg.sender) {
        nftContract = IERC721(_nftContract);
    }


    function listNFT(uint256 tokenId, uint256 price, uint256 duration, bool isAuction) external nonReentrant {
        require(price > 0, "Price must be greater than zero");
        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");

        nftContract.transferFrom(msg.sender, address(this), tokenId);

        uint256 endTime = block.timestamp + duration;
        listings[address(nftContract)][tokenId] = Listing(price, msg.sender, endTime, isAuction);
       

        emit NFTListed(address(nftContract), tokenId, price, endTime, isAuction, msg.sender);
    }

    function buyNFT(uint256 tokenId) external payable nonReentrant {
        Listing memory listing = listings[address(nftContract)][tokenId];
        require(!listing.isAuction, "This NFT is listed for auction");
        require(msg.value >= listing.price, "Insufficient payment");
        require(listing.seller != address(0), "NFT not listed for sale");

        delete listings[address(nftContract)][tokenId];
        nftContract.transferFrom(address(this), msg.sender, tokenId);

        uint256 fee = (msg.value * OPEN_SEA_FEE) / 1000;
        uint256 royalty = (msg.value * nftContract.royalties(tokenId)) / 1000;
        uint256 sellerProceeds = msg.value - fee - royalty;

        payable(listing.seller).transfer(sellerProceeds); // Seller gets their share
        payable(nftContract.Royalties(tokenId)).transfer(royalty); // Creator gets the royalty

        emit NFTSold(address(nftContract), tokenId, listing.price, msg.sender);
    }

    function placeBid(uint256 tokenId, uint256 bidAmount) external payable nonReentrant {
        Listing memory listing = listings[address(nftContract)][tokenId];
        require(listing.isAuction, "This NFT is not listed for auction");
        require(msg.value >= bidAmount, "Insufficient payment");
        require(bidAmount > highestBids[address(nftContract)][tokenId], "There already is a higher or equal bid");

        if (highestBids[address(nftContract)][tokenId] != 0) {
            payable(highestBidders[address(nftContract)][tokenId]).transfer(highestBids[address(nftContract)][tokenId]);
        }

        highestBids[address(nftContract)][tokenId] = bidAmount;
        highestBidders[address(nftContract)][tokenId] = msg.sender;

        if (block.timestamp >= listing.endTime) {
            finalizeAuction(tokenId);
        }

        emit NFTBidPlaced(address(nftContract), tokenId, bidAmount, msg.sender);
    }

    function finalizeAuction(uint256 tokenId) internal {
        Listing memory listing = listings[address(nftContract)][tokenId];

        address highestBidder = highestBidders[address(nftContract)][tokenId];
        uint256 highestBid = highestBids[address(nftContract)][tokenId];

        delete listings[address(nftContract)][tokenId];
        delete highestBidders[address(nftContract)][tokenId];
        delete highestBids[address(nftContract)][tokenId];

        nftContract.transferFrom(address(this), highestBidder, tokenId);

        uint256 fee = (highestBid * OPEN_SEA_FEE) / 1000;
        uint256 royalty = (highestBid * nftContract.royalties(tokenId)) / 1000;
        uint256 sellerProceeds = highestBid - fee - royalty;

        payable(listing.seller).transfer(sellerProceeds); // Seller gets their share
        payable(nftContract.Royalties(tokenId)).transfer(royalty); // Creator gets the royalty

        emit NFTSold(address(nftContract), tokenId, highestBid, highestBidder);
    }

    function editListing(uint256 tokenId, uint256 newPrice, uint256 newDuration) external nonReentrant {
        Listing storage listing = listings[address(nftContract)][tokenId];
        require(listing.seller == msg.sender, "Only seller can edit listing");
        require(block.timestamp < listing.endTime, "Listing has already ended");

        listing.price = newPrice;
        listing.endTime = block.timestamp + newDuration;

        emit NFTListed(address(nftContract), tokenId, newPrice, listing.endTime, listing.isAuction, msg.sender);
    }

    function cancelListing(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[address(nftContract)][tokenId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        delete listings[address(nftContract)][tokenId];
        nftContract.transferFrom(address(this), msg.sender, tokenId);

        if (listing.isAuction) {
            address highestBidder = highestBidders[address(nftContract)][tokenId];
            uint256 highestBid = highestBids[address(nftContract)][tokenId];

            if (highestBid != 0) {
                payable(highestBidder).transfer(highestBid);
                delete highestBidders[address(nftContract)][tokenId];
                delete highestBids[address(nftContract)][tokenId];
            }
        }

        emit NFTListingCancelled(address(nftContract), tokenId, msg.sender);
    }

    function transferNFT(uint256 tokenId, address to) external nonReentrant {
        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        nftContract.transferFrom(msg.sender, to, tokenId);
    }

    function makeOffer(uint256 tokenId, uint256 amount) external payable nonReentrant {
        require(msg.value >= amount, "Offer must be greater than zero");

        Offer memory newOffer = Offer({
            amount: amount,
            offerer: msg.sender
        });
        nftOffers[tokenId].push(newOffer);

        emit OfferMade(tokenId, msg.value, msg.sender);
    }

    function acceptOffer(uint256 tokenId, uint256 offerIndex) external nonReentrant {
        Listing memory listing = listings[address(nftContract)][tokenId];
        require(listing.seller == msg.sender, "Only seller can accept offers");
        require(offerIndex < nftOffers[tokenId].length, "Invalid offer index");

        Offer memory acceptedOffer = nftOffers[tokenId][offerIndex];

        nftContract.transferFrom(address(this), acceptedOffer.offerer, tokenId);

        uint256 fee = (acceptedOffer.amount * OPEN_SEA_FEE) / 1000;
        uint256 royalty = (acceptedOffer.amount * nftContract.royalties(tokenId)) / 1000;
        uint256 sellerProceeds = acceptedOffer.amount - fee - royalty;

        payable(listing.seller).transfer(sellerProceeds); // Seller gets their share
        payable(nftContract.Royalties(tokenId)).transfer(royalty); // Creator gets the royalty

        // Remove the accepted offer from the array
        nftOffers[tokenId][offerIndex] = nftOffers[tokenId][nftOffers[tokenId].length - 1];
        nftOffers[tokenId].pop();

        delete listings[address(nftContract)][tokenId];

        emit OfferAccepted(tokenId, acceptedOffer.amount, acceptedOffer.offerer, msg.sender);
    }
}
