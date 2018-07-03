module.exports = {
  networks: {
    rsk: {
      gas : 2500000,
      gasPrice : 0,
      from: "0x64cc8592be46687ba88dee29ddd8609fc0ea11b9",
      host: "35.207.14.219",
      port: 4444,
      network_id: "*" // Match any network id
    }
  }
};
