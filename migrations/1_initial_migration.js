var Migrations = artifacts.require("./Migrations.sol");

module.exports = function(deployer, network, accounts) {
  if (network == "development") {
    deployer.deploy(Migrations);
  }
};
