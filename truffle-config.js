// const HDWalletProvider = require('truffle-hdwallet-provider');
// const infuraKey = "fj4jll3k.....";
// const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1', // Localhost (default: none)
      port: 8545, // Standard Ethereum port (default: none)
      network_id: '*'
    }
  },
  compilers: {
    solc: {
      version: '0.8.0',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  },
  mocha: {
    enableTimeouts: false
  },
  plugins: ['solidity-coverage']
};
