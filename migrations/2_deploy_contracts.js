const FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
const owned = artifacts.require("./owned.sol");
const Exchange = artifacts.require("./Exchange.sol");

module.exports = (deployer) => {
    deployer.deploy(FixedSupplyToken);
    deployer.deploy(owned);
    deployer.deploy(Exchange);
};