module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  migrations_directory: "./migrations",
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8500,
      network_id: "3", // Match any network id
      gas: 7984452, // Block Gas Limit same as latest on Mainnet https://ethstats.net/
      gasPrice: 2000000000, // same as latest on Mainnet https://ethstats.net/
      // Mnemonic: "copy obey episode awake damp vacant protect hold wish primary travel shy"
      from: "0x7c06350cb8640a113a618004a828d3411a4f32d3"
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 500
    }
  }
};
