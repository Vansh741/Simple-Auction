# Simple Auction Smart Contract

A Solidity-based timed auction system where users can bid on items, and the highest bidder wins when the auction ends.

## Features

- ⏰ **Timed Auctions**: Set custom auction duration
- 💰 **Minimum Bid Protection**: Prevent spam bids below threshold
- 🏆 **Highest Bidder Wins**: Automatic winner determination
- 💸 **Automatic Refunds**: Outbid amounts are immediately withdrawable
- 🔒 **Security**: Reentrancy protection and safe withdrawal patterns
- 📊 **Real-time Tracking**: Live auction status and statistics

## Contract Overview

The `SimpleAuction` contract enables anyone to create a timed auction for any item. Bidders compete by placing increasingly higher bids, and the highest bidder at auction end wins the item.

### Key Components

- **Beneficiary**: The seller who receives the winning bid amount
- **Auction Duration**: Customizable time limit for bidding
- **Minimum Bid**: Prevents low-value spam bids
- **Pending Returns**: Automatic refund system for outbid amounts

## Getting Started

### Prerequisites

- Solidity ^0.8.0
- Ethereum development environment (Hardhat, Truffle, or Remix)
- MetaMask or similar wallet for testing

### Deployment

1. **Compile the contract**:
   ```bash
   solc SimpleAuction.sol
   ```

2. **Deploy with constructor parameters**:
   ```solidity
   constructor(
       uint256 _biddingTime,        // Duration in seconds
       uint256 _minimumBid,         // Minimum bid in wei
       string memory _itemName,     // Item name
       string memory _itemDescription // Item description
   )
   ```

### Example Deployment

```solidity
// Deploy a 2-hour auction for a vintage watch with 0.1 ETH minimum bid
SimpleAuction auction = new SimpleAuction(
    7200,  // 2 hours (7200 seconds)
    100000000000000000,  // 0.1 ETH (in wei)
    "Vintage Rolex Submariner",
    "1960s Rolex Submariner in excellent condition with original box"
);
```

## Usage Guide

### For Bidders

#### 1. Place a Bid
```solidity
// Bid must be higher than current highest bid and minimum bid
auction.bid{value: 0.5 ether}();
```

#### 2. Check Your Status
```solidity
// Check if you're the current highest bidder
bool isWinning = auction.isHighestBidder(msg.sender);

// Check how much you can withdraw
uint256 refundAmount = auction.getPendingReturn(msg.sender);
```

#### 3. Withdraw Outbid Amounts
```solidity
// Withdraw your previous bid if outbid
auction.withdraw();
```

### For Auction Monitoring

#### Check Auction Status
```solidity
// Get current auction state
(address highestBidder, uint256 highestBid, uint256 timeLeft, uint256 totalBids) = 
    auction.getAuctionStatus();

// Check if auction is still active
bool isActive = auction.isAuctionActive();

// Get time remaining
uint256 secondsLeft = auction.getTimeRemaining();
```

#### End the Auction
```solidity
// Anyone can end the auction after time expires
auction.auctionEnd();

// Get winner information
(address winner, uint256 winningBid) = auction.getWinner();
```

## Function Reference

### Core Functions

| Function | Description | Access |
|----------|-------------|---------|
| `bid()` | Place a bid (payable) | Public |
| `withdraw()` | Withdraw outbid amount | Public |
| `auctionEnd()` | End auction after time expires | Public |
| `emergencyEndAuction()` | End auction early | Beneficiary only |

### View Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `getAuctionDetails()` | Item info, minimum bid, end time | Auction metadata |
| `getAuctionStatus()` | Current bid info, time left | Live auction state |
| `getWinner()` | Winner address and amount | Final results |
| `isAuctionActive()` | Boolean | Whether bidding is open |
| `getTimeRemaining()` | Seconds | Time left in auction |
| `getAllBidders()` | Address array | List of all participants |

## Events

The contract emits the following events for frontend integration:

```solidity
event AuctionStarted(string itemName, uint256 minimumBid, uint256 endTime);
event HighestBidIncreased(address bidder, uint256 amount);
event AuctionEnded(address winner, uint256 amount);
event BidWithdrawn(address bidder, uint256 amount);
```

## Security Features

### Reentrancy Protection
- Uses checks-effects-interactions pattern
- Resets pending returns before external calls

### Safe Withdrawals
- Automatic refund system for outbid amounts
- No manual intervention required from auction creator

### Access Controls
- Time-based restrictions on bidding
- Beneficiary-only emergency controls

### Input Validation
- Minimum bid requirements
- Non-zero address checks
- Bid amount validations

## Common Use Cases

### Digital Asset Auctions
```sol
