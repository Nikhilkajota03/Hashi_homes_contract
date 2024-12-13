require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // For securely storing private keys in .env file

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.26",
  networks: {
    bnb: {
      url: "https://bsc-dataseed.binance.org/", // Mainnet RPC endpoint
      accounts: [process.env.PRIVATE_KEY], // Private key from .env file
    },
    bnbTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/", // Testnet RPC endpoint
      accounts: [process.env.PRIVATE_KEY], // Private key from .env file
    },
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY, // API key for BscScan verification
  },
};
