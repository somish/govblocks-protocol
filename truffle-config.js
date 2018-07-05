var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "waste brand belt below bullet leaf sign catch clay wet volume kind";

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      gasPrice : 1,
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"),
      network_id: 3
    },
    kovan: {
      gasPrice : 1,
      provider: new HDWalletProvider(mnemonic, "https://kovan.infura.io/"),
      network_id: 42
    },
    rinkeby: {
      gasPrice : 1,
      provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io"),
      network_id: 4
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};

