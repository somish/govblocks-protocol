var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "waste brand belt below bullet leaf sign catch clay wet volume kind";

module.exports = {
  networks: {
    development: {
      gasPrice : 1,
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://parity.motv.ml/");
      },
      network_id: "*"
    },
    ropsten: {
      gasPrice : 1,
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/");
      },      
      network_id: 3
    },
    rinkeby: {
      gasPrice : 1,
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/");
      },      
      network_id: 4
    },
    kovan: {
      gasPrice : 1,
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://kovan.infura.io/");
      },      
      network_id: 42
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
};

