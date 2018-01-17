// Specifically request an abstraction for FixedSupplyToken
var fixedSupplyToken = artifacts.require("FixedSupplyToken");

contract('FixedSupplyToken', function(accounts) {
  it("first account is owner and should own all tokens upon deployment of FixedSupplyToken contract", function() {
    var _totalSupply;
    var myTokenInstance;
    return fixedSupplyToken.deployed().then(function(instance) {
        myTokenInstance = instance;
        return myTokenInstance.totalSupply.call();
    }).then(function(totalSupply) {
        _totalSupply = totalSupply;
        return myTokenInstance.balanceOf(accounts[0]);
    }).then(function(balanceAccountOwner) {
        assert.equal(balanceAccountOwner.toNumber(), _totalSupply.toNumber(), "Total Amount of tokens is owned by owner");
    });
  });
});