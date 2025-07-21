# 🏠🌱 Eco Score NFTs for Homes

[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-purple.svg)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-orange.svg)](https://stacks.co/)

## 🌱 Overview

Transform your home into a verifiable sustainability asset! This smart contract creates NFTs representing homes with dynamic eco-scores that increase as you make environmental improvements. Perfect for green real estate, sustainability tracking, and creating on-chain proof of your eco-friendly investments.

## ✨ Features

- 🏡 **Home NFT Minting**: Create unique NFTs for individual properties
- 📊 **Dynamic Eco Scoring**: Calculate scores based on insulation, solar panels, rainwater systems, and more
- 🔍 **Inspector Verification**: Approved inspectors can verify and boost eco scores
- 💚 **Eco Credits System**: Earn tradable credits for sustainability improvements
- 🛒 **Marketplace Integration**: List and purchase eco-certified homes
- 📈 **Upgrade Tracking**: Complete history of all eco improvements

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <repository-url>
cd eco-score-nfts-for-homes
clarinet check
npm install
npm test
```

## 🎯 Core Functions

### 🏠 Minting a Home NFT

```clarity
(contract-call? .eco-score-nfts-for-homes mint-home-nft
  "123 Eco Street, Green City"  ;; address
  u8                            ;; insulation level (1-10)
  true                          ;; has solar panels
  true                          ;; has rainwater system
  u9                            ;; energy efficiency (1-10)
  u7)                           ;; waste management (1-10)
```

### 📊 Checking Eco Score

```clarity
(contract-call? .eco-score-nfts-for-homes get-eco-score u1)
```

### 🔍 Verifying Upgrades (Inspector Only)

```clarity
(contract-call? .eco-score-nfts-for-homes verify-upgrade
  u1                            ;; token-id
  "Solar Panel Installation"    ;; upgrade type
  u25)                          ;; score boost (1-50)
```

### 💰 Marketplace Operations

#### List for Sale
```clarity
(contract-call? .eco-score-nfts-for-homes list-for-sale u1 u1000000)
```

#### Purchase Home
```clarity
(contract-call? .eco-score-nfts-for-homes purchase-home u1)
```

## 📊 Scoring System

| Feature | Base Score |
|---------|------------|
| 🏠 Insulation Level | Level × 10 points |
| ☀️ Solar Panels | 20 points |
| 🌧️ Rainwater System | 15 points |
| ⚡ Energy Efficiency | Level × 5 points |
| ♻️ Waste Management | Level × 8 points |

**Upgrades**: Additional 1-50 points per verified improvement

## 👨‍🔧 Inspector Management

### Add Inspector (Contract Owner Only)
```clarity
(contract-call? .eco-score-nfts-for-homes add-inspector 'SP1234...)
```

### Remove Inspector (Contract Owner Only)
```clarity
(contract-call? .eco-score-nfts-for-homes remove-inspector 'SP1234...)
```

## 💚 Eco Credits System

- 🎁 **Earn**: Receive credits equal to upgrade score boosts
- 💸 **Transfer**: Send credits to other users
- 🏆 **Track**: Monitor total credits earned across the platform

### Transfer Credits
```clarity
(contract-call? .eco-score-nfts-for-homes transfer-eco-credits 'SP1234... u50)
```

## 📖 Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-eco-score` | Get complete eco score data for a home |
| `get-home-details` | Retrieve all home information |
| `get-upgrade-history` | View all verified upgrades |
| `get-eco-credits` | Check user's credit balance |
| `get-market-listing` | View marketplace listing details |
| `is-approved-inspector` | Check if address is approved inspector |

## 🏗️ Contract Architecture

The contract uses a modular design with separate data maps for scores, home details, inspector approvals, upgrade history, eco credits, and marketplace listings. This ensures efficient data storage and retrieval while maintaining clear separation of concerns.

## 🔧 Development

### Running Tests
```bash
npm test
```

### Type Checking
```bash
clarinet check
```

### Console Testing
```bash
clarinet console
```

## 🌍 Use Cases

- 🏡 **Green Real Estate**: Verify sustainability features before buying
- 🏆 **Sustainability Competitions**: Compete for highest eco scores
- 💰 **Carbon Credit Trading**: Trade earned eco credits
- 📊 **Property Valuation**: Factor eco scores into home values
- 🎯 **Improvement Tracking**: Monitor upgrade impact over time

## 🔐 Security Features

- ✅ Inspector verification required for score boosts
- ✅ Owner-only transfer restrictions
- ✅ Marketplace listing protections
- ✅ Credit balance validation
- ✅ Score range validation (1-10 for base features, 1-50 for upgrades)

## 📋 Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only action |
| u101 | Not token owner |
| u104 | Token not found |
| u106 | Already approved inspector |
| u107 | Not approved inspector |
| u108 | Invalid score range |
| u110 | Insufficient eco credits |

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://clarity-lang.org/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet)

---

Made with 💚 for a sustainable future 🌍
