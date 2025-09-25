# ArtisanPad

A comprehensive digital art provenance and marketplace platform built on the Stacks blockchain using Clarity smart contracts.

## Overview

ArtisanPad revolutionizes the digital art industry by providing a secure, transparent, and decentralized platform for artists to mint, verify, and trade their digital artworks. The platform ensures authentic provenance tracking, fair royalty distribution, and seamless marketplace functionality with support for both unique artworks, limited edition collections, and time-based auctions.

## Features

### Core Functionality
- **Digital Art Minting**: Artists can create and mint their digital artworks with metadata
- **Multi-Edition NFTs**: Support for limited edition artworks with sequential minting and rarity tracking
- **Auction System**: Time-based bidding mechanism with automatic settlement and reserve prices
- **Provenance Tracking**: Complete ownership history and transaction records
- **Artist Verification**: Verified artist profiles for enhanced credibility
- **Marketplace Integration**: Built-in buying and selling functionality
- **Royalty System**: Automatic royalty distribution to original creators
- **Collection Management**: Personal artwork collections for users
- **Rarity Metrics**: Automatic rarity calculation for edition tokens

### Smart Contract Features
- **Secure Transactions**: All transactions secured by Bitcoin through Stacks
- **Automated Royalties**: Smart contract-based royalty payments
- **Platform Fees**: Sustainable platform fee structure (2.5%)
- **Error Handling**: Comprehensive error handling and validation
- **Gas Optimization**: Efficient contract design for minimal transaction costs
- **Edition Management**: Automatic sold-out tracking and supply limits
- **Auction Management**: Automated bid handling, settlement, and refunds

### Auction System Features
- **Timed Auctions**: Configurable auction duration (1-30 days)
- **Reserve Prices**: Minimum sale price protection for sellers
- **Automatic Bidding**: Real-time bid validation and outbid notifications
- **Automatic Settlement**: Smart contract handles payment distribution
- **Bid Refunds**: Automatic refund system for outbid participants
- **Auction Cancellation**: Cancel auctions with no bids placed

## Technical Architecture

### Smart Contract Structure
```
ArtisanPad Contract
├── Data Maps
│   ├── artworks (artwork metadata and ownership)
│   ├── editions (limited edition series data)
│   ├── edition-tokens (individual edition token tracking)
│   ├── auctions (auction data and status)
│   ├── auction-bids (bid tracking and amounts)
│   ├── artist-profiles (artist information and stats)
│   ├── artwork-provenance (transaction history)
│   └── user-collections (ownership tracking)
├── Public Functions
│   ├── create-artist-profile
│   ├── create-artwork (single NFTs)
│   ├── create-edition (limited edition series)
│   ├── mint-edition-token
│   ├── create-auction (start timed auction)
│   ├── place-bid (participate in auctions)
│   ├── settle-auction (finalize completed auctions)
│   ├── cancel-auction (cancel auctions with no bids)
│   ├── purchase-artwork (direct purchase)
│   ├── list-artwork-for-sale
│   ├── remove-artwork-from-sale
│   └── verify-artist
└── Read-only Functions
    ├── get-artwork
    ├── get-edition
    ├── get-edition-token
    ├── get-auction
    ├── get-auction-bid
    ├── is-auction-active
    ├── can-settle-auction
    ├── get-artist-profile
    ├── get-artwork-provenance
    ├── get-edition-rarity
    └── owns-artwork
```

### Data Models

**Artwork Data Structure:**
- Title, description, and image hash
- Creator and current owner information
- Pricing and sale status
- Royalty percentage configuration
- Creation timestamp and sale history
- Edition tracking (is-edition flag and edition-id)

**Edition Data Structure:**
- Series metadata and creator information
- Total supply and minted count tracking
- Pricing and royalty configuration
- Active status and sold-out detection

**Edition Token Structure:**
- Individual token ownership and metadata
- Minting timestamp and artwork linking
- Secondary market sale tracking

**Auction Data Structure:**
- Artwork ID and seller information
- Start price and reserve price settings
- Current bid and highest bidder tracking
- Start and end block timestamps
- Settlement status and activity flags

**Artist Profile Structure:**
- Name, biography, and verification status
- Total artworks, editions, and sales completed
- Reputation and credibility metrics

## Installation & Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks CLI for deployment
- Node.js for frontend development (future implementation)

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd artisan-pad
   ```

2. **Initialize Clarinet project:**
   ```bash
   clarinet check
   ```

3. **Run tests:**
   ```bash
   clarinet test
   ```

4. **Deploy to testnet:**
   ```bash
   clarinet deploy --testnet
   ```

## Usage

### For Artists

1. **Create Artist Profile:**
   ```clarity
   (contract-call? .artisan-pad create-artist-profile "Artist Name" "Artist bio and description")
   ```

2. **Mint Single Artwork:**
   ```clarity
   (contract-call? .artisan-pad create-artwork 
     "Artwork Title" 
     "Detailed description" 
     "image-hash-string" 
     u1000000 ;; Price in microSTX
     u500)    ;; 5% royalty
   ```

3. **Create Limited Edition Series:**
   ```clarity
   (contract-call? .artisan-pad create-edition
     "Edition Title"
     "Edition description"
     "image-hash-string"
     u100     ;; Total supply
     u500000  ;; Price per edition in microSTX
     u750)    ;; 7.5% royalty
   ```

4. **Start an Auction:**
   ```clarity
   (contract-call? .artisan-pad create-auction
     u1       ;; Artwork ID
     u500000  ;; Starting price in microSTX
     u1000000 ;; Reserve price in microSTX
     u1440)   ;; Duration in blocks (10 days)
   ```

5. **List for Sale:**
   ```clarity
   (contract-call? .artisan-pad list-artwork-for-sale u1 u2000000)
   ```

### For Collectors

1. **Purchase Regular Artwork:**
   ```clarity
   (contract-call? .artisan-pad purchase-artwork u1)
   ```

2. **Mint Edition Token:**
   ```clarity
   (contract-call? .artisan-pad mint-edition-token u1)
   ```

3. **Place Auction Bid:**
   ```clarity
   (contract-call? .artisan-pad place-bid u1 u750000)
   ```

4. **Settle Completed Auction:**
   ```clarity
   (contract-call? .artisan-pad settle-auction u1)
   ```

5. **Check Ownership:**
   ```clarity
   (contract-call? .artisan-pad owns-artwork tx-sender u1)
   ```

6. **Check Auction Status:**
   ```clarity
   (contract-call? .artisan-pad is-auction-active u1)
   ```

## Contract Functions

### Public Functions
- `create-artist-profile`: Register as an artist on the platform
- `create-artwork`: Mint a new single digital artwork
- `create-edition`: Create a new limited edition series
- `mint-edition-token`: Mint an individual token from an edition series
- `create-auction`: Start a timed auction for an artwork
- `place-bid`: Place a bid on an active auction
- `settle-auction`: Finalize a completed auction and transfer ownership
- `cancel-auction`: Cancel an auction with no bids placed
- `purchase-artwork`: Buy an artwork from another user
- `list-artwork-for-sale`: Put artwork up for sale
- `remove-artwork-from-sale`: Remove artwork from marketplace
- `verify-artist`: Admin function to verify artist profiles

### Read-only Functions
- `get-artwork`: Retrieve artwork details
- `get-edition`: Get edition series information
- `get-edition-token`: Get specific edition token details
- `get-auction`: Get auction details and current status
- `get-auction-bid`: Get bid amount for specific bidder
- `is-auction-active`: Check if auction is currently accepting bids
- `can-settle-auction`: Check if auction can be settled
- `get-artist-profile`: Get artist profile information
- `get-artwork-provenance`: View transaction history
- `get-edition-rarity`: Calculate rarity score for edition tokens
- `owns-artwork`: Check artwork ownership
- `get-next-artwork-id`: Get next available artwork ID
- `get-next-edition-id`: Get next available edition ID
- `get-next-auction-id`: Get next available auction ID

## Auction System

### How Auctions Work

1. **Creation**: Artwork owners can create timed auctions with configurable duration (1-30 days)
2. **Bidding**: Users place bids that must exceed the current highest bid and starting price
3. **Automatic Refunds**: Previous highest bidders are automatically refunded when outbid
4. **Reserve Protection**: Auctions only complete if the final bid meets the reserve price
5. **Settlement**: Anyone can settle completed auctions, triggering automatic payment distribution
6. **Fee Distribution**: Platform fees and royalties are automatically calculated and distributed

### Auction Parameters

- **Duration**: 144 blocks (1 day) to 4,320 blocks (30 days)
- **Starting Price**: Minimum bid amount to participate
- **Reserve Price**: Minimum price for successful auction completion
- **Bid Increments**: Each bid must exceed the current highest bid
- **Settlement Window**: Auctions can be settled immediately after end time

### Security Features

- **Ownership Verification**: Only artwork owners can create auctions
- **Bid Validation**: All bids are validated for amount and timing
- **Automatic Escrow**: Contract holds all funds until settlement
- **Refund Protection**: Guaranteed refunds for outbid participants
- **Double Settlement Prevention**: Auctions can only be settled once

## Multi-Edition NFT Features

### Edition Creation
- Artists can create limited edition series with customizable supply limits (1-10,000 tokens)
- Each edition has its own pricing, royalty structure, and metadata
- Automatic sold-out detection and series deactivation

### Sequential Minting
- Tokens are minted sequentially with unique token numbers
- Each minted token becomes an individual artwork with full marketplace functionality
- Automatic rarity calculation based on token number and total supply

### Rarity Tracking
- Built-in rarity scoring system based on minting order
- Lower token numbers typically have higher rarity scores
- Transparent rarity metrics for collectors and traders

### Edition Management
- Real-time tracking of minted vs. total supply
- Automatic series closure when sold out
- Individual token ownership and transfer capabilities

## Security Features

- **Input Validation**: All user inputs are validated for security
- **Access Control**: Ownership verification for sensitive operations
- **Error Handling**: Comprehensive error codes and messages
- **Reentrancy Protection**: Safe transaction handling
- **Data Integrity**: Immutable provenance records
- **Supply Limits**: Edition size constraints prevent overselling
- **Auction Security**: Automated bid validation and settlement protection

## Economic Model

- **Platform Fee**: 2.5% of each transaction
- **Royalty System**: Configurable royalties (0-10%) for original creators
- **Edition Pricing**: Flexible pricing per edition token
- **Auction Fees**: Same fee structure applied to auction settlements
- **Gas Optimization**: Efficient contract design for minimal costs
- **Sustainable Revenue**: Platform fees support ongoing development

## Error Codes

- `u100`: Not authorized
- `u101`: Artwork not found
- `u102`: Invalid price
- `u103`: Insufficient funds
- `u104`: Artwork not for sale
- `u105`: Invalid royalty percentage
- `u106`: Already exists
- `u107`: Invalid input
- `u108`: Edition sold out
- `u109`: Invalid edition size
- `u110`: Edition not found
- `u111`: Invalid edition number
- `u112`: Auction not found
- `u113`: Auction not active
- `u114`: Bid too low
- `u115`: Auction ended
- `u116`: Auction not ended
- `u117`: No bids placed
- `u118`: Auction already settled
- `u119`: Invalid auction duration

## Roadmap

ArtisanPad is continuously evolving to become the most comprehensive digital art platform. Here's what's coming next:

### 🎯 Phase 1 - Core Enhancements (Current)
- ✅ **Multi-Edition NFTs**: Support for limited edition artworks with sequential minting and rarity tracking
- ✅ **Auction System**: Time-based bidding mechanism with automatic settlement and reserve prices
- 🔄 **Collaborative Artworks**: Multi-artist collaboration support with split ownership and revenue sharing

### 🚀 Phase 2 - Advanced Features (Q3-Q4 2025)
- 📊 **Art Investment Pools**: Fractional ownership system allowing multiple investors to co-own high-value artworks
- 🤖 **Dynamic Pricing Algorithm**: AI-driven pricing suggestions based on artist reputation, market trends, and artwork characteristics
- 🌉 **Cross-Chain Bridge**: Integration with other blockchain networks for broader artwork accessibility

### 🎨 Phase 3 - Immersive Experience (Q1-Q2 2026)
- 🏛️ **Virtual Gallery System**: 3D virtual spaces for artwork display and immersive viewing experiences
- 🤝 **Artwork Lending Protocol**: Temporary artwork transfers for exhibitions, galleries, and events
- 👥 **Artist Mentorship Program**: Structured system connecting established artists with emerging creators

### 🌱 Phase 4 - Sustainability & Social Impact (Q3-Q4 2026)
- 🌍 **Carbon Offset Integration**: Environmental impact tracking and automatic carbon credit purchasing for eco-conscious art trading
- 📈 **Advanced Analytics Dashboard**: Comprehensive market insights and portfolio tracking tools
- 🔐 **Enhanced Security Features**: Multi-signature wallets and advanced fraud protection

### 💡 Future Innovations
- AR/VR artwork visualization tools
- AI-powered art authentication systems
- Decentralized governance for platform decisions
- Social features and artist community building
- Mobile app with full platform functionality

Stay tuned for updates and join our community to influence the development roadmap!

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add comprehensive tests
5. Submit a pull request

### Development Priorities
We welcome contributions in the following areas:
- Smart contract optimizations and security improvements
- Frontend development for the marketplace interface
- Testing framework expansion and edge case coverage
- Documentation improvements and developer guides
- Integration with external services and APIs