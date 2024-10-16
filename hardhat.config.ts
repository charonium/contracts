import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-ignition-viem";
import * as dotenv from "dotenv";
dotenv.config();

let {
  BASESCAN_API_KEY,
  BASE_SEPOLIA_URL,
  BASE_SEPOLIA_PRIVATE_KEY,
  BASE_URL,
  BASE_MNEMONIC,
  CREATE2_SALT
} = process.env;

BASESCAN_API_KEY ??= ""


const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
    },
  },
  ignition: {
    strategyConfig: {
      create2: {
        salt: CREATE2_SALT!
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    base: {
      url: BASE_URL,
      accounts: {
        initialIndex: 0,
        count: 20,
        mnemonic: BASE_MNEMONIC,
        path: "m/44'/60'/0'/0",
      }
    },
    baseSepolia: {
      chainId: 84532,
      url: BASE_SEPOLIA_URL,
      accounts: [BASE_SEPOLIA_PRIVATE_KEY!],
      gasMultiplier: 1.01
    },
  },
  etherscan: {
    apiKey: {
      base: BASESCAN_API_KEY,
      baseSepolia: BASESCAN_API_KEY
    },

    customChains: [
      {
        network: "baseSepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org"
        }
      }
    ]
  },
  sourcify: {
    enabled: true
  },
};

export default config;
