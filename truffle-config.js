//var HDWalletProvider = require("truffle-hdwallet-provider");

//var mnemonic = "word vocal hazard glory home property canvas duty fetch private wasp ozone";

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '5777'
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  mocha: {
    enableTimeouts: false
  }
};
