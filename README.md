# ArtisanPad

A comprehensive digital art provenance and marketplace platform built on the Stacks blockchain using Clarity smart contracts.

## Overview

ArtisanPad revolutionizes the digital art industry by providing a secure, transparent, and decentralized platform for artists to mint, verify, and trade their digital artworks. The platform ensures authentic provenance tracking, fair royalty distribution, and seamless marketplace functionality.

## Features

### Core Functionality
- **Digital Art Minting**: Artists can create and mint their digital artworks with metadata
- **Provenance Tracking**: Complete ownership history and transaction records
- **Artist Verification**: Verified artist profiles for enhanced credibility
- **Marketplace Integration**: Built-in buying and selling functionality
- **Royalty System**: Automatic royalty distribution to original creators
- **Collection Management**: Personal artwork collections for users

### Smart Contract Features
- **Secure Transactions**: All transactions secured by Bitcoin through Stacks
- **Automated Royalties**: Smart contract-based royalty payments
- **Platform Fees**: Sustainable platform fee structure (2.5%)
- **Error Handling**: Comprehensive error handling and validation
- **Gas Optimization**: Efficient contract design for minimal transaction costs

## Technical Architecture

### Smart Contract Structure
```
ArtisanPad Contract
├── Data Maps
│   ├── artworks (artwork metadata and ownership)
│   ├── artist-profiles (artist information and stats)
│   ├── artwork-provenance (transaction history)
│   └── user-collections (ownership tracking)
├── Public Functions
│   ├── create-artist-profile
│   ├── create-artwork
│   ├── purchase-artwork
│   ├── list-artwork-for-sale
│   ├── remove-artwork-from-sale
│   └── verify-artist
└── Read-only Functions
    ├── get-artwork
    ├── get-artist-profile
    ├── get-artwork-provenance
    └── owns-artwork
```

### Data Models

**Artwork Data Structure:**
- Title, description, and image hash
- Creator and current owner information
- Pricing and sale status
- Royalty percentage configuration
- Creation timestamp and sale history

**Artist Profile Structure:**
- Name, biography, and verification status
- Total artworks created and sales completed
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

2. **Mint Artwork:**
   ```clarity
   (contract-call? .artisan-pad create-artwork 
     "Artwork Title" 
     "Detailed description" 
     "image-hash-string" 
     u1000000 ;; Price in microSTX
     u500)    ;; 5% royalty
   ```

3. **List for Sale:**
   ```clarity
   (contract-call? .artisan-pad list-artwork-for-sale u1 u2000000)
   ```

### For Collectors

1. **Purchase Artwork:**
   ```clarity
   (contract-call? .artisan-pad purchase-artwork u1)
   ```

2. **Check Ownership:**
   ```clarity
   (contract-call? .artisan-pad owns-artwork tx-sender u1)
   ```

## Contract Functions

### Public Functions
- `create-artist-profile`: Register as an artist on the platform
- `create-artwork`: Mint a new digital artwork
- `purchase-artwork`: Buy an artwork from another user
- `list-artwork-for-sale`: Put artwork up for sale
- `remove-artwork-from-sale`: Remove artwork from marketplace
- `verify-artist`: Admin function to verify artist profiles

### Read-only Functions
- `get-artwork`: Retrieve artwork details
- `get-artist-profile`: Get artist profile information
- `get-artwork-provenance`: View transaction history
- `owns-artwork`: Check artwork ownership
- `get-next-artwork-id`: Get next available artwork ID

## Security Features

- **Input Validation**: All user inputs are validated for security
- **Access Control**: Ownership verification for sensitive operations
- **Error Handling**: Comprehensive error codes and messages
- **Reentrancy Protection**: Safe transaction handling
- **Data Integrity**: Immutable provenance records

## Economic Model

- **Platform Fee**: 2.5% of each transaction
- **Royalty System**: Configurable royalties (0-10%) for original creators
- **Gas Optimization**: Efficient contract design for minimal costs
- **Sustainable Revenue**: Platform fees support ongoing development

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add comprehensive tests
5. Submit a pull request

