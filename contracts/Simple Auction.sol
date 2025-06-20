// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleAuction - A Timed Auction Contract
 * @dev Users can bid on an item within a time limit, highest bidder wins
 */
contract SimpleAuction {
    // Auction parameters
    address payable public beneficiary;  // Seller who receives the payment
    uint256 public auctionEndTime;       // Timestamp when auction ends
    string public itemName;              // Name of the item being auctioned
    string public itemDescription;       // Description of the item
    uint256 public minimumBid;           // Minimum bid amount
    
    // Current auction state
    address public highestBidder;        // Address of current highest bidder
    uint256 public highestBid;           // Current highest bid amount
    bool public auctionEnded;            // Whether auction has been ended
    
    // Bid tracking
    mapping(address => uint256) public pendingReturns;  // Bids that can be withdrawn
    address[] public bidders;            // List of all bidders
    uint256 public totalBids;            // Total number of bids placed
    
    // Events
    event AuctionStarted(string itemName, uint256 minimumBid, uint256 endTime);
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event BidWithdrawn(address bidder, uint256 amount);
    
    // Modifiers
    modifier onlyBefore(uint256 _time) {
        require(block.timestamp < _time, "Too late");
        _;
    }
    
    modifier onlyAfter(uint256 _time) {
        require(block.timestamp >= _time, "Too early");
        _;
    }
    
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only beneficiary can call this");
        _;
    }
    
    modifier auctionNotEnded() {
        require(!auctionEnded, "Auction has already ended");
        _;
    }
    
    /**
     * @dev Constructor - Creates auction with specified parameters
     * @param _biddingTime Duration of auction in seconds
     * @param _minimumBid Minimum bid amount in wei
     * @param _itemName Name of the item being auctioned
     * @param _itemDescription Description of the item
     */
    constructor(
        uint256 _biddingTime,
        uint256 _minimumBid,
        string memory _itemName,
        string memory _itemDescription
    ) {
        beneficiary = payable(msg.sender);
        auctionEndTime = block.timestamp + _biddingTime;
        minimumBid = _minimumBid;
        itemName = _itemName;
        itemDescription = _itemDescription;
        
        emit AuctionStarted(_itemName, _minimumBid, auctionEndTime);
    }
    
    /**
     * @dev Place a bid on the auction item
     * Bid must be higher than current highest bid and minimum bid
     */
    function bid() public payable 
        onlyBefore(auctionEndTime) 
        auctionNotEnded 
    {
        require(msg.value >= minimumBid, "Bid amount is below minimum bid");
        require(msg.value > highestBid, "There is already a higher or equal bid");
        
        // If there was a previous highest bidder, add their bid to pending returns
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        // Update highest bid and bidder
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        // Track bidder if they haven't bid before
        if (pendingReturns[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        
        totalBids++;
        
        emit HighestBidIncreased(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw a bid that was outbid
     * Bidders can withdraw their funds after being outbid
     */
    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        
        if (amount > 0) {
            // Reset the pending return before sending to prevent re-entrancy attacks
            pendingReturns[msg.sender] = 0;
            
            // Send the amount back to the bidder
            if (!payable(msg.sender).send(amount)) {
                // If send fails, restore the pending return
                pendingReturns[msg.sender] = amount;
                return false;
            }
            
            emit BidWithdrawn(msg.sender, amount);
        }
        
        return true;
    }
    
    /**
     * @dev End the auction and send highest bid to beneficiary
     * Can be called by anyone after auction end time
     */
    function auctionEnd() public onlyAfter(auctionEndTime) auctionNotEnded {
        auctionEnded = true;
        
        emit AuctionEnded(highestBidder, highestBid);
        
        // Transfer the highest bid to the beneficiary
        if (highestBid > 0) {
            beneficiary.transfer(highestBid);
        }
    }
    
    /**
     * @dev Emergency end auction (only beneficiary)
     * Allows auction creator to end early if needed
     */
    function emergencyEndAuction() public onlyBeneficiary auctionNotEnded {
        auctionEnded = true;
        
        emit AuctionEnded(highestBidder, highestBid);
        
        // Transfer the highest bid to the beneficiary
        if (highestBid > 0) {
            beneficiary.transfer(highestBid);
        }
    }
    
    /**
     * @dev Get auction details
     * @return itemName, itemDescription, minimumBid, endTime, ended
     */
    function getAuctionDetails() public view returns (
        string memory,
        string memory,
        uint256,
        uint256,
        bool
    ) {
        return (itemName, itemDescription, minimumBid, auctionEndTime, auctionEnded);
    }
    
    /**
     * @dev Get current auction status
     * @return highestBidder, highestBid, timeLeft, totalBids
     */
    function getAuctionStatus() public view returns (
        address,
        uint256,
        uint256,
        uint256
    ) {
        uint256 timeLeft = 0;
        if (block.timestamp < auctionEndTime && !auctionEnded) {
            timeLeft = auctionEndTime - block.timestamp;
        }
        
        return (highestBidder, highestBid, timeLeft, totalBids);
    }
    
    /**
     * @dev Check if auction is still active
     * @return bool indicating if auction is active
     */
    function isAuctionActive() public view returns (bool) {
        return block.timestamp < auctionEndTime && !auctionEnded;
    }
    
    /**
     * @dev Get time remaining in auction
     * @return seconds remaining (0 if auction ended)
     */
    function getTimeRemaining() public view returns (uint256) {
        if (auctionEnded || block.timestamp >= auctionEndTime) {
            return 0;
        }
        return auctionEndTime - block.timestamp;
    }
    
    /**
     * @dev Get pending return amount for a bidder
     * @param _bidder Address of the bidder
     * @return amount that can be withdrawn
     */
    function getPendingReturn(address _bidder) public view returns (uint256) {
        return pendingReturns[_bidder];
    }
    
    /**
     * @dev Get all bidders who have participated
     * @return array of bidder addresses
     */
    function getAllBidders() public view returns (address[] memory) {
        return bidders;
    }
    
    /**
     * @dev Get auction winner (only after auction ends)
     * @return winner address and winning bid amount
     */
    function getWinner() public view returns (address, uint256) {
        require(auctionEnded || block.timestamp >= auctionEndTime, "Auction is still active");
        return (highestBidder, highestBid);
    }
    
    /**
     * @dev Check if a specific address is the current highest bidder
     * @param _bidder Address to check
     * @return bool indicating if address is highest bidder
     */
    function isHighestBidder(address _bidder) public view returns (bool) {
        return _bidder == highestBidder;
    }
    
    /**
     * @dev Get contract balance (should be 0 after auction ends and funds are distributed)
     * @return contract balance in wei
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Fallback function to reject direct payments
     */
    receive() external payable {
        revert("Use bid() function to place bids");
    }
}
