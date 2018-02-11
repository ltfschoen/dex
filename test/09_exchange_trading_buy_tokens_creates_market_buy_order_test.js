const fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
const exchange = artifacts.require("./Exchange.sol");

contract('Exchange - Buy Tokens - Market Buy Order', (accounts) => {

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

    it("should create a Market Buy Orders for Tokens when sell prices are below buy price", () => {
        let myExchangeInstance;
        return exchange.deployed().then((instance) => {
            myExchangeInstance = instance;
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        }).then((orderBook) => {
            assert.equal(orderBook.length, 2, "SellOrderBook should have 2 elements");
            assert.equal(orderBook[0].length, 0, "OrderBook should have 0 buy offers");
            return myExchangeInstance.sellToken("FIXED", web3.toWei(4, "finney"), 5, {from: accounts[1]});
        }).then((txResult) => {
            // Event Log Test
            assert.equal(txResult.logs.length, 1, "One Log Message should have been emitted");
            assert.equal(txResult.logs[0].event, "LimitSellOrderCreated", "Log Event should be LimitSellOrderCreated");
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        }).then((orderBook) => {
            assert.equal(orderBook[0].length, 1, "OrderBook should have 1 sell offers");
            assert.equal(orderBook[1].length, 1, "OrderBook should have 1 sell volume has one element");
            assert.equal(orderBook[1][0], 5, "OrderBook should have a volume of 5 coins someone wants to sell");
            // Note: priceInWei for the buyToken should be greater than or equal to the priceInWei for the sellToken to 
            // execute a Market Buy Order immediately followed by a Buy Limit Order for the remainder, 
            // otherwise only a Buy Limit Order is created.
            return myExchangeInstance.buyToken("FIXED", web3.toWei(4, "finney"), 5, {from: accounts[0], gas: 4000000});
        }).then((txResult) => {
            console.log(txResult);
            console.log(txResult.logs[0].args);

            // Event Log Test
            assert.equal(txResult.logs.length, 1, "One Log Message should have been emitted");
            assert.equal(txResult.logs[0].event, "BuyOrderFulfilled", "Log Event should be BuyOrderFulfilled");
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        }).then((orderBook) => {
            assert.equal(orderBook[0].length, 0, "OrderBook should have 0 buy offers");
            assert.equal(orderBook[1].length, 0, "OrderBook should have 0 buy volume has one element");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            assert.equal(orderBook[0].length, 0, "OrderBook should have 0 sell offers");
            assert.equal(orderBook[1].length, 0, "OrderBook should have 0 sell volume elements");
        });
    });
});