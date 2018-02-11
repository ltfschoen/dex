const fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
const exchange = artifacts.require("./Exchange.sol");

contract('Exchange - Buy Tokens - Buy Limit Order', (accounts) => {

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

    it("should create a Buy Limit Order for Tokens when no sell prices exist or sell prices are above buy price", () => {
      let myExchangeInstance;
      return exchange.deployed().then((instance) => {
          myExchangeInstance = instance;
          return myExchangeInstance.getSellOrderBook.call("FIXED");
      }).then((orderBook) => {
          assert.equal(orderBook.length, 2, "SellOrderBook should have 2 elements");
          assert.equal(orderBook[0].length, 0, "OrderBook should have 0 buy offers");
          // Create a Sell Price that will be higher than the Buy Price
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
          // Create a Buy Price that is less than the lowest Sell Price of the token to trigger a Buy Limit Order
          // instead of an immediate Market Buy Order
          return myExchangeInstance.buyToken("FIXED", web3.toWei(3, "finney"), 5);
      }).then((txResult) => {
          // Event Log Test
          assert.equal(txResult.logs.length, 1, "One Log Message should have been emitted");
          assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "Log Event should be LimitBuyOrderCreated");
          return myExchangeInstance.getSellOrderBook.call("FIXED");
      }).then((orderBook) => {
          // Order Book should still have 1 Sell Offer since no Market Buy Order was executed as lowest Sell Price was higher than Buy Offer
          assert.equal(orderBook[0].length, 1, "OrderBook should still have 1 sell offers");
          assert.equal(orderBook[1].length, 1, "OrderBook should still have 1 sell volume has one element");
          return myExchangeInstance.getBuyOrderBook.call("FIXED");
      }).then((orderBook) => {
          // Order Book should now have 1 Buy Offer since no Market Buy Order was executed as lowest Sell Price was higher than Buy Offer
          assert.equal(orderBook[0].length, 1, "OrderBook should have 0 buy offers");
          assert.equal(orderBook[1].length, 1, "OrderBook should have 0 buy volume elements");
      });
    });
});