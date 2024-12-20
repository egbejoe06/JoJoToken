// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Token.sol";

contract NFTStore is ERC721URIStorage {
    JonathanToken public paymentToken;
    uint256 public listingFeePercent = 20;
    uint256 private currentTokenId;

    struct NFTListing {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool isForSale;
    }

    struct Auction {
        uint256 tokenId;
        address payable owner;
        uint256 startingPrice;
        uint256 highestBid;
        address payable highestBidder;
        uint256 endTime;
        bool active;
    }

    mapping(uint256 => NFTListing) private tokenIdToListing;
    mapping(uint256 => Auction) private tokenIdToAuction;

    modifier onlyAdmin() {
        require(paymentToken.admins(msg.sender), "Only admin can call this function");
        _;
    }

    constructor(address _paymentToken) ERC721("NFTStore", "NFTS") {
        paymentToken = JonathanToken(_paymentToken);
    }

    function updateListingFeePercent(uint256 _listingFeePercent) public onlyAdmin {
        listingFeePercent = _listingFeePercent;
    }

    function createToken(string memory _tokenURI, uint256 _price) public onlyAdmin returns (uint256) {
        require(_price > 0, "Price must be greater than zero");

        currentTokenId++;
        uint256 newTokenId = currentTokenId;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        _createNFTListing(newTokenId, _price);

        return newTokenId;
    }

    function _createNFTListing(uint256 _tokenId, uint256 _price) private {
        tokenIdToListing[_tokenId] = NFTListing({
            tokenId: _tokenId,
            owner: payable(msg.sender),
            seller: payable(msg.sender),
            price: _price,
            isForSale: true
        });
    }

    function purchaseWithToken(uint256 tokenId) public {
        NFTListing storage listing = tokenIdToListing[tokenId];
        require(listing.isForSale, "NFT is not for sale");

        uint256 listingFee = (listing.price * listingFeePercent) / 100;
        uint256 sellerAmount = listing.price - listingFee;

        require(paymentToken.transferFrom(msg.sender, listing.seller, sellerAmount), "Token transfer to seller failed");
        require(paymentToken.transferFrom(msg.sender, address(this), listingFee), "Fee transfer failed");

        _transfer(listing.owner, msg.sender, tokenId);

        listing.owner = payable(msg.sender);
        listing.seller = payable(address(0));
        listing.isForSale = false;
                // Remove from listing
        delete tokenIdToListing[tokenId];
    }

    function startAuction(uint256 tokenId, uint256 startingPrice, uint256 duration) public {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can start an auction");
        require(!tokenIdToAuction[tokenId].active, "Auction is already active");

        tokenIdToAuction[tokenId] = Auction({
            tokenId: tokenId,
            owner: payable(msg.sender),
            startingPrice: startingPrice,
            highestBid: 0,
            highestBidder: payable(address(0)),
            endTime: block.timestamp + duration,
            active: true
        });
    }
    function cancelAuction(uint256 tokenId) public {
        Auction storage auction = tokenIdToAuction[tokenId];
        require(auction.active, "Auction is not active");
        require(msg.sender == auction.owner, "Only the auction owner can cancel the auction");

        // Refund the highest bidder if a bid exists
        if (auction.highestBid > 0) {
            require(
                paymentToken.transfer(auction.highestBidder, auction.highestBid),
                "Refund to highest bidder failed"
            );
        }

        // Mark the auction as inactive
        auction.active = false;
        auction.highestBid = 0;
        auction.highestBidder = payable(address(0));
        auction.endTime = 0;
    }

    // Other auction-related functions remain the same as in the original contract
    function placeBid(uint256 tokenId, uint256 bidAmount) public {
        Auction storage auction = tokenIdToAuction[tokenId];
        require(auction.active, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(bidAmount > auction.highestBid, "Bid must be higher than the current highest bid");

        // Transfer tokens from bidder to this contract
        require(paymentToken.transferFrom(msg.sender, address(this), bidAmount), "Bid transfer failed");

        // Refund previous highest bidder if exists
        if (auction.highestBid > 0) {
            require(paymentToken.transfer(auction.highestBidder, auction.highestBid), "Refund failed");
        }

        auction.highestBid = bidAmount;
        auction.highestBidder = payable(msg.sender);
    }

    function endAuction(uint256 tokenId) public {
        Auction storage auction = tokenIdToAuction[tokenId];
        require(auction.active, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction is not yet over");
        require(msg.sender == auction.owner, "Only the owner can end the auction");

        if (auction.highestBid > 0) {
            uint256 listingFee = (auction.highestBid * listingFeePercent) / 100;
            uint256 sellerAmount = auction.highestBid - listingFee;

            // Transfer funds to seller and fee to contract
            require(paymentToken.transfer(auction.owner, sellerAmount), "Seller transfer failed");
            require(paymentToken.transfer(address(this), listingFee), "Fee transfer failed");

            _transfer(auction.owner, auction.highestBidder, tokenId);
        }

        auction.active = false;
    }
    function getNFTsByOwner(address owner) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(owner);
    uint256[] memory ownedTokenIds = new uint256[](balance);

    uint256 currentIndex = 0;

    // Loop through all minted tokens to check ownership
    for (uint256 i = 1; i <= currentTokenId; i++) {
        if (ownerOf(i) == owner) {
            ownedTokenIds[currentIndex] = i;
            currentIndex++;
        }
    }

    return ownedTokenIds;
}
    function getAllNFTs() public view returns (uint256[] memory) {
        uint256[] memory allTokenIds = new uint256[](currentTokenId);
        for (uint256 i = 1; i <= currentTokenId; i++) {
            allTokenIds[i - 1] = i;
        }
        return allTokenIds;
    }
function getAllNFTsForSale() public view returns (NFTListing[] memory) {
    uint256 totalTokens = currentTokenId;
    uint256 count = 0;

    // First, count how many NFTs are for sale
    for (uint256 i = 1; i <= totalTokens; i++) {
        if (tokenIdToListing[i].isForSale) {
            count++;
        }
    }

    // Create an array to store the listings
    NFTListing[] memory listingsForSale = new NFTListing[](count);
    uint256 index = 0;

    // Populate the array with NFTs that are for sale
    for (uint256 i = 1; i <= totalTokens; i++) {
        if (tokenIdToListing[i].isForSale) {
            listingsForSale[index] = tokenIdToListing[i];
            index++;
        }
    }

    return listingsForSale;
}
function getActiveAuctions() public view returns (Auction[] memory) {
    uint256 totalTokens = currentTokenId;
    uint256 count = 0;

    // Count active auctions
    for (uint256 i = 1; i <= totalTokens; i++) {
        if (tokenIdToAuction[i].active) {
            count++;
        }
    }

    // Create an array for active auctions
    Auction[] memory activeAuctions = new Auction[](count);
    uint256 index = 0;

    for (uint256 i = 1; i <= totalTokens; i++) {
        if (tokenIdToAuction[i].active) {
            activeAuctions[index] = tokenIdToAuction[i];
            index++;
        }
    }

    return activeAuctions;
}

    // Optional: Function to withdraw collected fees (only by admin)
    function withdrawFees() public onlyAdmin {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(paymentToken.transfer(msg.sender, balance), "Withdrawal failed");
    }
}