const fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
const exchange = artifacts.require("./Exchange.sol");

contract('Exchange - Buy, Sell, and Cancel Limit Orders', (accounts) => {

    before(() => {
        // Setup Exchange with 3 Ether and 2000 "FIXED" Tokens so we may Buy/Sell Tokens 
        let instanceExchange;
        let instanceToken;
        return exchange.deployed().then((instance) => {
            instanceExchange = instance;
            return instanceExchange.depositEther({from: accounts[0], value: web3.toWei(3, "ether")});
        }).then((txResult) => {
            return fixedSupplyToken.deployed();
        }).then((myTokenInstance) => {
            instanceToken = myTokenInstance;
            return instanceExchange.addToken("FIXED", instanceToken.address);
        }).then((txResult) => {
            return instanceToken.approve(instanceExchange.address, 2000);
        }).then((txResult) => {
            return instanceExchange.depositToken("FIXED", 2000);
        });
    });

    it("should be possible to Add a Buy Limit Order and get Buy Order Book", () => {
        let myExchangeInstance;
        return exchange.deployed().then((instance) => {
            myExchangeInstance = instance;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            // Verify the Buy Order Book has a Buy Prices Array and Buy Volume Array
            assert.equal(orderBook.length, 2, "BuyOrderBook should have 2 elements");
            // Verify that in Initial State the Order Book has no Buy Offers
            assert.equal(orderBook[0].length, 0, "OrderBook should have 0 buy offers");
            // Buy Limit Order for 5x "FIXED"-Tokens @ 1 Finney each
            return myExchangeInstance.buyToken("FIXED", web3.toWei(1, "finney"), 5);
        }).then((txResult) => {
            // console.log(txResult);
            // Event Log Test
            assert.equal(txResult.logs.length, 1, "One Log Message should have been emitted.");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "Log Event should be LimitBuyOrderCreated");
            // Retireve the Buy Order Book from the Exchange for the "FIXED" Token
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            // Verify that the Buy Order Book "Prices Array" has a length of 1 (i.e. [ 1 Finney ])
            assert.equal(orderBook[0].length, 1, "OrderBook should have 0 buy offers");
            // Verify that the Buy Order Book "Volume Array" has a length of 1 (i.e. [ 5 OFF ])
            assert.equal(orderBook[1].length, 1, "OrderBook should have 0 buy volume has one element");
        });
    });

    // Add two more Buy Limit Orders in Buy Order Book, where one order should be at the End of the Linked List,
    // and the other in the Middle of the Linked List
    it("should be possible to Add three (3) Buy Limit Orders and get Buy Order Book", () => {
        let myExchangeInstance;
        let orderBookLengthBeforeBuy;
        return exchange.deployed().then((exchangeInstance) => {
            myExchangeInstance = exchangeInstance;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            orderBookLengthBeforeBuy = orderBook[0].length;
            // Buy Limit Order for 5x "FIXED"-Tokens @ 2 Finney each (End of the Linked List)
            return myExchangeInstance.buyToken("FIXED", web3.toWei(2, "finney"), 5);
        }).then((txResult) => {
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "Log Event should be LimitBuyOrderCreated");
            // Buy Limit Order for 5x "FIXED"-Tokens @ 1.4 Finney each (Middle of the Linked List)
            return myExchangeInstance.buyToken("FIXED", web3.toWei(1.4, "finney"), 5);
        }).then((txResult) => {
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "Log Event should be LimitBuyOrderCreated");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            // Verify that the Order Book has changed to 3x Price Entries
            assert.equal(orderBook[0].length, orderBookLengthBeforeBuy + 2, "OrderBook should have one more Buy Offers");
            assert.equal(orderBook[1].length, orderBookLengthBeforeBuy + 2, "OrderBook should have 2x Buy Volume elements");
        });
    });

    it("should be possible to Add two Sell Limit Orders and get Sell Order Book", () => {
        var myExchangeInstance;
        return exchange.deployed().then((instance) => {
            myExchangeInstance = instance;
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        }).then((orderBook) => {
            return myExchangeInstance.sellToken("FIXED", web3.toWei(3, "finney"), 5);
        }).then((txResult) => {
            // console.log(txResult);
            // Event Log Test
            assert.equal(txResult.logs.length, 1, "One Log Message should be emitted.");
            assert.equal(txResult.logs[0].event, "LimitSellOrderCreated", "Log Event should be LimitSellOrderCreated");
            return myExchangeInstance.sellToken("FIXED", web3.toWei(6, "finney"), 5);
        }).then((txResult) => {
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        }).then((orderBook) => {
            assert.equal(orderBook[0].length, 2, "OrderBook should have 2 sell offers");
            assert.equal(orderBook[1].length, 2, "OrderBook should have 2 sell volume elements");
        });
    });

    it("should be possible to Create and Cancel a Buy Limit Order", () => {
        let myExchangeInstance;
        let orderBookLengthBeforeBuy, orderBookLengthAfterBuy, orderBookLengthAfterCancel, orderKey;
        return exchange.deployed().then((instance) => {
            myExchangeInstance = instance;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            orderBookLengthBeforeBuy = orderBook[0].length;
            console.log(`Order Book Length Before Buy: ${orderBookLengthBeforeBuy}`);
            // Buy Limit Order for 5x "FIXED"-Tokens @ 2.2 Finney each (End of the Linked List)
            return myExchangeInstance.buyToken("FIXED", web3.toWei(2.2, "finney"), 5);
        }).then((txResult) => {
            // Event Log Test
            assert.equal(txResult.logs.length, 1, "One Log Message should be emitted.");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "Log Event should be LimitBuyOrderCreated");
            orderKey = txResult.logs[0].args._orderKey;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            orderBookLengthAfterBuy = orderBook[0].length;
            console.log(`Order Book Length After Buy: ${orderBookLengthAfterBuy}`);
            assert.equal(orderBookLengthAfterBuy, orderBookLengthBeforeBuy + 1, "OrderBook should have 1 Buy Offer more than before");
            return myExchangeInstance.cancelOrder("FIXED", false, web3.toWei(2.2, "finney"), orderKey);
        }).then((txResult) => {
            console.log(txResult);
            console.log(txResult.logs[0].args);
            assert.equal(txResult.logs[0].event, "BuyOrderCanceled", "Log Event should be BuyOrderCanceled");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((orderBook) => {
            orderBookLengthAfterCancel = orderBook[0].length;
            console.log(orderBook[1][orderBookLengthAfterCancel-1])
            assert.equal(
                orderBookLengthAfterCancel, 
                orderBookLengthAfterBuy, 
                "OrderBook should have 1 Buy Offers. It is setting Volume to zero instead of Cancelling it");
            assert.equal(orderBook[1][orderBookLengthAfterCancel-1], 0, "Available Volume should be zero");
        });
    });
});