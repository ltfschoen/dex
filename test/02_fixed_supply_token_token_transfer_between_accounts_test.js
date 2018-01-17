// Specifically request an abstraction for FixedSupplyToken
const fixedSupplyToken = artifacts.require("FixedSupplyToken");

contract('FixedSupplyToken - token transfer between accounts', (accounts) => {

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