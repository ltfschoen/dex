const fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
const exchange = artifacts.require("./Exchange.sol");

contract('Exchange - add token into DEX, deposit token into DEX from an account and then withdraw \
          it again', (accounts) => {

    it("should allow DEX owner to add token to DEX", () => {
        let myTokenInstance;
        let myExchangeInstance;
        return fixedSupplyToken.deployed().then((instance) => {
            myTokenInstance = instance;
            return exchange.deployed();
        }).then(function (exchangeInstance) {
            myExchangeInstance = exchangeInstance;
            return myExchangeInstance.addToken("FIXED", myTokenInstance.address);
        }).then(function () {
            return myExchangeInstance.hasToken.call("FIXED");
        }).then(function (booleanHasToken) {
            assert.equal(booleanHasToken, true, "Token provided could not be added to DEX");
            return myExchangeInstance.hasToken.call("SOMETHING");
        }).then(function (booleanHasNotToken) {
            assert.equal(booleanHasNotToken, false, "Token provided was found by was never added to DEX");
        });
    });

    it("should allow an account address to Deposit Tokens into DEX", () => {
        let myExchangeInstance;
        let myTokenInstance;
        return fixedSupplyToken.deployed().then((instance) => {
            myTokenInstance = instance;
            return instance;
        }).then((tokenInstance) => {
            myTokenInstance = tokenInstance;
            return exchange.deployed();
        }).then((exchangeInstance) => {
            myExchangeInstance = exchangeInstance;
            // Grant approval to DEX to transfer up to 2000 tokens on behalf of the caller's account address
            return myTokenInstance.approve(myExchangeInstance.address, 2000);
        }).then((txResult) => {
            return myExchangeInstance.depositToken("FIXED", 2000);
        }).then((txResult) => {
            return myExchangeInstance.getBalance("FIXED");
        }).then((balanceToken) => {
            assert.equal(balanceToken, 2000, "DEX should have 2000 tokens for the \
                account address that is calling the DEX");
        });
    });

    it("should allow an account address to Withdraw Tokens from DEX", () => {
        let myExchangeInstance;
        let myTokenInstance;
        let balancedTokenInExchangeBeforeWithdrawal;
        let balanceTokenInTokenBeforeWithdrawal;
        let balanceTokenInExchangeAfterWithdrawal;
        let balanceTokenInTokenAfterWithdrawal;

        return fixedSupplyToken.deployed().then((instance) => {
            myTokenInstance = instance;
            return instance;
        }).then((tokenInstance) => {
            myTokenInstance = tokenInstance;
            return exchange.deployed();
        }).then((exchangeInstance) => {
            myExchangeInstance = exchangeInstance;
            return myExchangeInstance.getBalance.call("FIXED");
        }).then((balanceExchange) => {
            balancedTokenInExchangeBeforeWithdrawal = balanceExchange.toNumber();
            return myTokenInstance.balanceOf.call(accounts[0]);
        }).then((balanceToken) => {
            balanceTokenInTokenBeforeWithdrawal = balanceToken.toNumber();
            return myExchangeInstance.withdrawToken("FIXED", balancedTokenInExchangeBeforeWithdrawal);
        }).then((txResult) => {
            return myExchangeInstance.getBalance.call("FIXED");
        }).then((balanceExchange) => {
            balanceTokenInExchangeAfterWithdrawal = balanceExchange.toNumber();
            return  myTokenInstance.balanceOf.call(accounts[0]);
        }).then((balanceToken) => {
            balanceTokenInTokenAfterWithdrawal = balanceToken.toNumber();
            assert.equal(
                balanceTokenInExchangeAfterWithdrawal, 
                0, 
                "DEX should have 0 tokens left after the withdrawal"
            );
            assert.equal(
                balanceTokenInTokenAfterWithdrawal, 
                balancedTokenInExchangeBeforeWithdrawal + balanceTokenInTokenBeforeWithdrawal, 
                "Token Contract should have all the tokens withdrawn from the DEX"
            );
        });
    });
});