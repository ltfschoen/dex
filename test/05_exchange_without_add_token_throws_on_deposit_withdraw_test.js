const fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
const exchange = artifacts.require("./Exchange.sol");

contract('Exchange - without adding token to DEX an error is thrown upon deposit token \
          into DEX from an account and for withdraw and token balance checks', (accounts) => {

    it("should throw error when account address tries to check Balance of Tokens on DEX \
        that were not previously added to DEX", () => {
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
            return myTokenInstance.approve(myExchangeInstance.address, 2000);
        }).then((txResult) => {
            return myExchangeInstance.getBalance("FIXED");
        }).then((returnValue) => {
            assert(false, "getBalance was supposed to throw but did not");
        }).catch(function(error) {
          let expectedError = "revert"
          if(error.toString().indexOf(expectedError) != -1) {
            console.log(`Solidity threw an expected error: ${expectedError} successfully`);
          } else {
            assert(false, `Solidity threw an unexpected error: ${error.toString()}`);
          }
        });
    });

    it("should throw error when account address tries to Deposit Tokens into DEX \
        that were not previously added to DEX", () => {
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
            return myTokenInstance.approve(myExchangeInstance.address, 2000);
        }).then((txResult) => {
            return myExchangeInstance.depositToken("FIXED", 2000);
        }).then((returnValue) => {
            assert(false, "depositToken was supposed to throw but did not");
        }).catch(function(error) {
          let expectedError = "revert"
          if(error.toString().indexOf(expectedError) != -1) {
            console.log(`Solidity threw an expected error: ${expectedError} successfully`);
          } else {
            assert(false, `Solidity threw an unexpected error: ${error.toString()}`);
          }
        });
    });

    it("should throw an error when account address tries to Withdraw Tokens from DEX \
        when not previously added to DEX", () => {
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
        }).then((returnValue) => {
            assert(false, "getBalance was supposed to throw but did not");
        }).catch(function(error) {
          let expectedError = "revert";
          if(error.toString().indexOf(expectedError) != -1) {
            console.log(`Solidity threw an expected error: ${expectedError} successfully`);
          } else {
            // if the error is something else (e.g., the assert from previous promise), then we fail the test
            assert(false, `Solidity threw an unexpected error: ${error.toString()}`);
          }
        });
    });
});