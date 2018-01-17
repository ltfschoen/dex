// Specifically request an abstraction for FixedSupplyToken
const fixedSupplyToken = artifacts.require("FixedSupplyToken");

contract('FixedSupplyToken - initial account token ownership upon deployment', (accounts) => {

  it("first account is owner and should own all tokens upon deployment of FixedSupplyToken contract", () => {
    let _totalSupply;
    let myTokenInstance;
    return fixedSupplyToken.deployed().then((instance) => {
      myTokenInstance = instance;
      return myTokenInstance.totalSupply.call();
    }).then((totalSupply) => {
      _totalSupply = totalSupply;
      return myTokenInstance.balanceOf(accounts[0]);
    }).then((balanceAccountOwner) => {
      assert.equal(balanceAccountOwner.toNumber(), _totalSupply.toNumber(), "Total Amount of tokens is owned by owner");
    });
  });

  it("second account in TestRPC should own no tokens", () => {
    let myTokenInstance;
    return fixedSupplyToken.deployed().then((instance) => {
      myTokenInstance = instance;
      return myTokenInstance.balanceOf(accounts[1]);
    }).then((balanceAccountOwner) => {
      assert.equal(balanceAccountOwner.toNumber(), 0, "Total Amount of tokens is owned by some other address");
    });
  });

  it("should send token correctly between accounts", () => {
    let token;

    // Get initial balances of first and second account
    const account_one = accounts[0];
    const account_two = accounts[1];

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    let amount = 10;

    return fixedSupplyToken.deployed().then((instance) => {
      token = instance;
      return token.balanceOf.call(account_one);
    }).then((balance) => {
      account_one_starting_balance = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then((balance) => {
      account_two_starting_balance = balance.toNumber();
      return token.transfer(account_two, amount, {from: account_one});
    }).then(() => {
      return token.balanceOf.call(account_one);
    }).then((balance) => {
      account_one_ending_balance = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then((balance) => {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount was not correctly received from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount was not correctly sent to the receiver");
    });
  });
});