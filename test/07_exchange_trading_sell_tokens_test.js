const fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
const exchange = artifacts.require("./Exchange.sol");

contract('Exchange - Sell Tokens', (accounts) => {

    before(() => {
        let instanceExchange;
        let instanceToken;
        return exchange.deployed().then((instance) => {
            instanceExchange = instance;
            return instanceExchange.depositEther({
                from: accounts[0], 
                value: web3.toWei(3, "ether")
            });
        }).then((txResult) => {
            return fixedSupplyToken.deployed();
        }).then((myTokenInstance) => {
            instanceToken = myTokenInstance;
            return instanceExchange.addToken("FIXED", instanceToken.address);
        }).then((txResult) => {
            return instanceToken.transfer(accounts[1], 2000);
        }).then((txResult) => {
            return instanceToken.approve(instanceExchange.address, 2000, {from: accounts[1]});
        }).then((txResult) => {
            return instanceExchange.depositToken("FIXED", 2000, {from: accounts[1]});
        });
    });

    it("should be possible to Sell Tokens", () => {
        let myExchangeInstance;
        return exchange.deployed().then((instance) => {
            myExchangeInstance = instance;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            assert.equal(orderBook.length, 2, "BuyOrderBook should have 2 elements");
            assert.equal(orderBook[0].length, 0, "OrderBook should have 0 buy offers");
            return myExchangeInstance.buyToken("FIXED", web3.toWei(3, "finney"), 5);
        }).then((txResult) => {
            // Event Log Test
            console.log(`Buy Token Event Logs: ${JSON.stringify(txResult.logs[0].args, null, 2)}`);
            assert.equal(txResult.logs.length, 1, "One Log Message should be emitted");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "Log Event should be LimitBuyOrderCreated");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            console.log(`Order Book after Buy Token with Order Book 0: ${orderBook[0]}`);
            console.log(`Order Book after Buy Token with Order Book 1: ${orderBook[1]}`);
            assert.equal(orderBook[0].length, 1, "OrderBook should have 1 buy offers");
            assert.equal(orderBook[1].length, 1, "OrderBook should have 1 buy volume has one element");
            assert.equal(orderBook[1][0], 5, "OrderBook should have a volume of 5 coins someone wants to buy");
            return myExchangeInstance.sellToken("FIXED", web3.toWei(2, "finney"), 5, {from: accounts[1]});
        }).then((txResult) => {
            // Event Log Test
            console.log(`Sell Token Event Logs: ${JSON.stringify(txResult.logs[0].args, null, 2)}`);
            assert.equal(txResult.logs.length, 1, "One Log Message should be emitted");
            assert.equal(txResult.logs[0].event, "SellOrderFulfilled", "Log Event should be SellOrderFulfilled");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            console.log(`Order Book after Sell Token with Order Book 0: ${orderBook[0]}`);
            console.log(`Order Book after Sell Token with Order Book 1: ${orderBook[1]}`);
            assert.equal(orderBook[0].length, 0, "OrderBook should have 0 buy offers");
            assert.equal(orderBook[1].length, 0, "OrderBook should have 0 buy volume has one element");
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        }).then((orderBook) => {
            assert.equal(orderBook[0].length, 0, "OrderBook should have 0 sell offers");
            assert.equal(orderBook[1].length, 0, "OrderBook should have 0 sell volume elements");
        });
    });
});