# CHARONIUM® Smart Contracts

This repository contains the core smart contracts for the Charonium token ecosystem, built on Base blockchain.

## Overview

CHARONIUM® implements a comprehensive tokenomics system with controlled distribution mechanisms, including an ICO and various vesting schedules. The system consists of three main contracts:

### 1. CHARONIUM® Token Contract (ERC20)

Key features:
- Standard ERC20 implementation with additional security features
- Initial supply: 690,000,000 tokens
- Advanced whitelisting mechanism for controlled transfers
- Built-in token burning capability
- ERC20Permit support for gasless approvals
- One-time transition from restricted to unrestricted transfers
- Whitelist management for initial distribution phase

### 2. ICO Contract

Advanced ICO implementation with:
- Dynamic pricing using Chainlink price feeds (EUR/USD)
- Fixed token price: 0.069 EUR
- Three-phase token release mechanism:
  - 1/3 immediate release
  - 2/3 vested over specified period
- Built-in vesting schedule for ICO participants
- Pausable functionality for emergency scenarios
- Real-time ETH/EUR conversion using Chainlink oracles
- Separate TokenHolder contract for secure token custody

### 3. Vesting Contract

Sophisticated vesting mechanism featuring:
- Customizable vesting schedules per beneficiary
- Configurable cliff periods
- Linear or custom release schedules
- Revocable vesting options
- Multi-beneficiary support
- Clear schedule tracking and management
- Emergency revocation capabilities
- Granular release controls

## Token Distribution

Total Supply: 690,000,000 CHAR tokens distributed across:
- Team: 69,000,000 (12-month cliff, 24-month vesting)
- Advisors & Legal: 27,600,000 (12-month cliff, 24-month vesting)
- Strategic: 55,200,000 (8-month cliff, 16-month vesting)
- Liquidity Pool: 69,000,000 (no cliff, 18-month vesting)
- Ecosystem: 82,800,000 (no cliff, 36-month vesting)
- Treasury: 89,700,000 (no cliff, 36-month vesting)

## Security Features

- Reentrancy protection
- Secure ownership management
- Emergency pause functionality
- Whitelist controls
- Time-locked transfers
- Protected vesting schedules

## Dependencies

- OpenZeppelin Contracts v4.x
- Chainlink Price Feeds
- Solmate (for optimized implementations)

## Networks

- Mainnet: Base
- Price Feeds:
  - ETH/USD: `0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70`
  - EUR/USD: `0xc91D87E81faB8f93699ECf7Ee9B44D11e1D53F0F`

## License

MIT License

## Author

TP
