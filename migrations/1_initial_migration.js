const Migrations = artifacts.require("./Migrations.sol");

module.exports = (deployer, network, accounts) => {
  if (network == "development") {
    deployer.deploy(Migrations);
  }
};
