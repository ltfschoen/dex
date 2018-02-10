pragma solidity ^0.4.18;

import "./owned.sol";
import "./FixedSupplyToken.sol";

contract Exchange is owned {

    ///////////////////////
    // GENERAL STRUCTURE //
    ///////////////////////

    struct Offer {
        uint amount;
        address who;
    }

    struct OrderBook {
        uint higherPrice;
        uint lowerPrice;
        
        // All Keys are Initialised by Default in Solidity
        mapping (uint => Offer) offers;
        
        // Store in `offers_key` where we are in the Linked List
        uint offers_key;

        // Store amount of offers that we have
        uint offers_length;
    }

    struct Token {
        address tokenContract;
        string symbolName;

        // Note: Solidity Mappings have initialised state by default
        // (i.e. offers_length is initially 0)
        mapping (uint => OrderBook) buyBook;

        uint curBuyPrice;
        uint lowestBuyPrice;
        uint amountBuyPrices;

        mapping (uint => OrderBook) sellBook;

        uint curSellPrice;
        uint highestSellPrice;
        uint amountSellPrices;
    }

    // Max amount of tokens supported is 255
    mapping (uint8 => Token) tokens;
    uint8 symbolNameIndex;

    //////////////
    // BALANCES //
    //////////////

    mapping (address => mapping (uint8 => uint)) tokenBalanceForAddress;

    mapping (address => uint) balanceEthForAddress;

    ////////////
    // EVENTS //
    ////////////

    // Add Token to DEX
    event TokenAddedToSystem(uint _symbolIndex, string _token, uint _timestamp);


    // Deposit / Withdrawal of Tokens
    event DepositForTokenReceived(address indexed _from, uint indexed _symbolIndex, uint _amount, uint _timestamp);
    event WithdrawalToken(address indexed _to, uint indexed _symbolIndex, uint _amount, uint _timestamp);
    
    // Deposit / Withdrawal of Ether
    event DepositForEthReceived(address indexed _from, uint _amount, uint _timestamp);
    event WithdrawalEth(address indexed _to, uint _amount, uint _timestamp);

    // Creation of Buy / Sell Limit Orders
    event LimitBuyOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);
    event LimitSellOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);

    // Fulfillment of Buy / Sell Order
    event BuyOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);
    event SellOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);

    // Cancellation of Buy / Sell Order
    event BuyOrderCanceled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);
    event SellOrderCanceled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);

    ////////////////////////////////
    // DEPOSIT / WITHDRAWAL ETHER //
    ////////////////////////////////

    function depositEther() public payable {
        // Overflow check since `uint` (i.e. uint 256) in mapping for 
        // tokenBalanceForAddress has upper limit and undesirably 
        // restarts from zero again if we overflow the limit
        require(balanceEthForAddress[msg.sender] + msg.value >= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] += msg.value;
        DepositForEthReceived(msg.sender, msg.value, now);
    }

    function withdrawEther(uint amountInWei) public {
        // Balance sufficient to withdraw check
        require(balanceEthForAddress[msg.sender] - amountInWei >= 0);
        // Overflow check
        require(balanceEthForAddress[msg.sender] - amountInWei <= balanceEthForAddress[msg.sender]);
        // Deduct from balance and transfer the withdrawal amount
        balanceEthForAddress[msg.sender] -= amountInWei;
        msg.sender.transfer(amountInWei);
        WithdrawalEth(msg.sender, amountInWei, now);
    }

    function getEthBalanceInWei() public constant returns (uint) {
        // Get balance in Wei of calling address
        return balanceEthForAddress[msg.sender];
    }

    //////////////////////
    // TOKEN MANAGEMENT //
    //////////////////////

    function addToken(string symbolName, address erc20TokenAddress) public onlyowner {
        // Modifier checks if caller is Admin "owner" of the Contract otherwise return early

        // Use `hasToken` to check if given Token Symbol Name 
        // with ERC-20 Token Address is already in the Exchange
        require(!hasToken(symbolName));

        // If given Token is not already in the Exchange then:
        // - Increment the `symbolNameIndex` by 1
        // - Assign to a Mapping a new entry with the new `symbolNameIndex`,
        //   and the given Token Symbol Name and ERC-20 Token Address
        // Note: Throw an exception upon failure
        symbolNameIndex++;
        tokens[symbolNameIndex].symbolName = symbolName;
        tokens[symbolNameIndex].tokenContract = erc20TokenAddress;
        TokenAddedToSystem(symbolNameIndex, symbolName, now);
    }

    function hasToken(string symbolName) public constant returns (bool) {
        uint8 index = getSymbolIndex(symbolName);
        if (index == 0) {
            return false;
        }
        return true;
    }

    function getSymbolIndex(string symbolName) internal returns (uint8) {
        for (uint8 i = 1; i <= symbolNameIndex; i++) {
            if (stringsEqual(tokens[i].symbolName, symbolName)) {
                return i;
            }
        }
        return 0;
    }

    function getSymbolIndexOrThrow(string symbolName) returns (uint8) {
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);
        return index;
    }

    ////////////////////////////////
    // STRING COMPARISON FUNCTION //
    ////////////////////////////////

    // TODO - Try using sha3 to compare strings since it should use less gas than the loop comparing bytes
    function stringsEqual(string storage _a, string memory _b) internal returns (bool) {
        // Note:
        // - `storage` is default for Local Variables
        // - `storage` is what variables are forced to be if they are State Variables
        // - `memory` is the default for Function Parameters (and Function Return Parameters)
        //
        // Since first Function Parameter is a Local Variable (from the Mapping defined in the Class)
        // it is assigned as a `storage` Variable, whereas since the second Function Parameter is
        // a direct Function Argument it is assigned as a `memory` Variable
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);

        // // Compare two strings quickly by length to try to avoid detailed loop comparison
        // // - Transaction cost (with 5x characters): ~24k gas
        // // - Execution cost upon early exit here: ~1.8k gas
        // if (a.length != b.length)
        //     return false;
        
        // // Compare two strings in detail Bit-by-Bit
        // // - Transaction cost (with 5x characters): ~29.5k gas
        // // - Execution cost (with 5x characters): ~7.5k gas
        // for (uint i = 0; i < a.length; i++)
        //     if (a[i] != b[i])
        //         return false;

        // // Byte values of string are the same
        // return true;

        // Compare two strings using SHA3, which is supposedly more Gas Efficient 
        // - Transaction cost (with 5x characters): ~24k gas
        // - Execution cost upon early exit here: ~2.4k gas
        if (sha3(a) != sha3(b)) { return false; }
        return true;
    }

    ////////////////////////////////
    // DEPOSIT / WITHDRAWAL TOKEN //
    ////////////////////////////////

    function depositToken(string symbolName, uint amount) public {
        uint8 symbolNameIndex = getSymbolIndexOrThrow(symbolName);
        // Check the Token Contract Address is initialised and not an uninitialised address(0) aka "0x0"
        require(tokens[symbolNameIndex].tokenContract != address(0));

        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);

        // Transfer an amount to this DEX from the calling address 
        require(token.transferFrom(msg.sender, address(this), amount) == true);
        // Overflow check
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] + amount >= tokenBalanceForAddress[msg.sender][symbolNameIndex]);
        // Credit the DEX token balance for the callinging address with the transferred amount 
        tokenBalanceForAddress[msg.sender][symbolNameIndex] += amount;
        DepositForTokenReceived(msg.sender, symbolNameIndex, amount, now);
    }

    function withdrawToken(string symbolName, uint amount) public {
        uint8 symbolNameIndex = getSymbolIndexOrThrow(symbolName);
        require(tokens[symbolNameIndex].tokenContract != address(0));

        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);

        // Check sufficient balance to withdraw requested amount
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] - amount >= 0);
        // Overflow check to ensure future balance less than or equal to the current balance after deducting the withdrawn amount
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] - amount <= tokenBalanceForAddress[msg.sender][symbolNameIndex]);
        // Deduct amount requested to be withdrawing from the DEX Token Balance
        tokenBalanceForAddress[msg.sender][symbolNameIndex] -= amount;
        // Check that the `transfer` function of the Token Contract returns true
        require(token.transfer(msg.sender, amount) == true);
        WithdrawalToken(msg.sender, symbolNameIndex, amount, now);
    }

    function getBalance(string symbolName) public constant returns (uint) {
        uint8 symbolNameIndex = getSymbolIndexOrThrow(symbolName);
        return tokenBalanceForAddress[msg.sender][symbolNameIndex];
    }

    ///////////////////////////////////
    // ORDER BOOK - BID ORDERS       //
    ///////////////////////////////////

    // Returns Buy Prices Array and Buy Volume Array for each of the Prices
    function getBuyOrderBook(string symbolName) public constant returns (uint[], uint[]) {
        uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
        // Initialise New Memory Arrays with the Exact Amount of Buy Prices in the Buy Order Book (not a Dynamic Array) 
        uint[] memory arrPricesBuy = new uint[](tokens[tokenNameIndex].amountBuyPrices);
        uint[] memory arrVolumesBuy = new uint[](tokens[tokenNameIndex].amountBuyPrices);

        // Example:
        // - Assume 3x Buy Offers (1x 100 Wei, 1x 200 Wei, 1x 300 Wei)
        // - Start Counter at 0 with Lowest Buy Offer (i.e. 100 Wei) 
        //   - `whilePrice` becomes 100 Wei
        //   - Add Price `whilePrice` of 100 Wei to Buy Prices Array for Counter 0
        //   - Obtain Volume at 100 Wei by Summing all Offers for 100 Wei in Buy Order Book
        //   - Add Volume at 100 Wei to Buy Prices Array for Counter 0
        //   - Either
        //     - Assign Next Buy Offer (i.e. 200 Wei) to `whilePrice`.
        //       Else Break if we have reached Last Element (Higher Price of `whilePrice` points to `whilePrice`)
        //   - Increment Counter to 1 (Next Index in Prices Array and Volume Array)
        //   - Repeat
        //   - Break when Higher Price of 300 Wei is also 300 Wei
        // - Return Buy Prices Array and Buy Volumes Array
        // 
        // So if Buy Offers are: 50 Tokens @ 100 Wei, 70 Tokens @ 200 Wei, and 30 Tokens @ 300 Wei, then have:
        //  - 3x Entries in Buy Prices Array (i.e. [ 100, 200, 300 ])
        //  - 3x Entries in Buy Volumes Array (i.e. [ 50, 70, 30 ] )

        // Loop through Prices. Adding each to the Prices Array and Volume Array.
        // Starting from Lowest Buy Price until reach Current Buy Price (Highest Bid Price)
        uint whilePrice = tokens[tokenNameIndex].lowestBuyPrice;
        uint counter = 0;
        // Check Exists at Least One Order Book Entry
        if (tokens[tokenNameIndex].curBuyPrice > 0) {
            while (whilePrice <= tokens[tokenNameIndex].curBuyPrice) {
                arrPricesBuy[counter] = whilePrice;
                uint buyVolumeAtPrice = 0;
                uint buyOffersKey = 0;

                // Obtain the Volume from Summing all Offers Mapped to a Single Price inside the Buy Order Book
                buyOffersKey = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
                while (buyOffersKey <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length) {
                    buyVolumeAtPrice += tokens[tokenNameIndex].buyBook[whilePrice].offers[buyOffersKey].amount;
                    buyOffersKey++;
                }
                arrVolumesBuy[counter] = buyVolumeAtPrice;
                // Next whilePrice
                if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].higherPrice) {
                    break;
                }
                else {
                    whilePrice = tokens[tokenNameIndex].buyBook[whilePrice].higherPrice;
                }
                counter++;
            }
        }
        return (arrPricesBuy, arrVolumesBuy);
    }

    ///////////////////////////////////
    // ORDER BOOK - ASK ORDERS       //
    ///////////////////////////////////

    function getSellOrderBook(string symbolName) public constant returns (uint[], uint[]) {
        uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
        uint[] memory arrPricesSell = new uint[](tokens[tokenNameIndex].amountSellPrices);
        uint[] memory arrVolumesSell = new uint[](tokens[tokenNameIndex].amountSellPrices);
        uint sellWhilePrice = tokens[tokenNameIndex].curSellPrice;
        uint sellCounter = 0;
        if (tokens[tokenNameIndex].curSellPrice > 0) {
            while (sellWhilePrice <= tokens[tokenNameIndex].highestSellPrice) {
                arrPricesSell[sellCounter] = sellWhilePrice;
                uint sellVolumeAtPrice = 0;
                uint sellOffersKey = 0;
                sellOffersKey = tokens[tokenNameIndex].sellBook[sellWhilePrice].offers_key;
                while (sellOffersKey <= tokens[tokenNameIndex].sellBook[sellWhilePrice].offers_length) {
                    sellVolumeAtPrice += tokens[tokenNameIndex].sellBook[sellWhilePrice].offers[sellOffersKey].amount;
                    sellOffersKey++;
                }
                arrVolumesSell[sellCounter] = sellVolumeAtPrice;
                if (tokens[tokenNameIndex].sellBook[sellWhilePrice].higherPrice == 0) {
                    break;
                }
                else {
                    sellWhilePrice = tokens[tokenNameIndex].sellBook[sellWhilePrice].higherPrice;
                }
                sellCounter++;
            }
        }
        return (arrPricesSell, arrVolumesSell);
    }

    /////////////////////////////////
    // NEW ORDER - BID ORDER       //
    /////////////////////////////////

    // Market Buy Order Function
    // User wants to Buy X-Coins @ Y-Price per coin
    function buyToken(string symbolName, uint priceInWei, uint amount) public {
        // Obtain Symbol Index for given Symbol Name
        uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
        uint totalAmountOfEtherNecessary = 0;

        if (tokens[tokenNameIndex].amountSellPrices == 0 || tokens[tokenNameIndex].curSellPrice > priceInWei) {
            // Calculate Ether Balance necessary to Buy the Token Symbol Name.
            totalAmountOfEtherNecessary = amount * priceInWei;

            // Overflow Checks
            require(totalAmountOfEtherNecessary >= amount);
            require(totalAmountOfEtherNecessary >= priceInWei);
            require(balanceEthForAddress[msg.sender] >= totalAmountOfEtherNecessary);
            require(balanceEthForAddress[msg.sender] - totalAmountOfEtherNecessary >= 0);
            require(balanceEthForAddress[msg.sender] - totalAmountOfEtherNecessary <= balanceEthForAddress[msg.sender]);

            // Deduct from Exchange Balance the Ether amount necessary the Buy Limit Order.
            balanceEthForAddress[msg.sender] -= totalAmountOfEtherNecessary;

            // Create New Limit Order in the Order Book if either:
            // - No Sell Orders already exist that match the Buy Price Price Offered by the function caller
            // - Existing Sell Price is greater than the Buy Price Offered by the function caller

            // Add Buy Limit Order to Order Book
            addBuyOffer(tokenNameIndex, priceInWei, amount, msg.sender);
             
            // Emit Event.
            LimitBuyOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, tokens[tokenNameIndex].buyBook[priceInWei].offers_length);
        } else {
            // Execute Market Buy Order Immediately if:
            // - Existing Sell Limit Order exists that is less than or equal to the Buy Price Offered by the function caller

            uint totalAmountOfEtherAvailable = 0;
            uint whilePrice = tokens[tokenNameIndex].curSellPrice;
            uint amountOfTokensNecessary = amount;
            uint offers_key;
            while (whilePrice <= priceInWei && amountOfTokensNecessary > 0) {
                offers_key = tokens[tokenNameIndex].sellBook[whilePrice].offers_key;
                while (offers_key <= tokens[tokenNameIndex].sellBook[whilePrice].offers_length && amountOfTokensNecessary > 0) {
                    uint volumeAtPriceFromAddress = tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount;

                    if (volumeAtPriceFromAddress <= amountOfTokensNecessary) {

                        totalAmountOfEtherAvailable = volumeAtPriceFromAddress * whilePrice;

                        // Overflow Check
                        require(balanceEthForAddress[msg.sender] >= totalAmountOfEtherAvailable);
                        require(balanceEthForAddress[msg.sender] - totalAmountOfEtherAvailable <= balanceEthForAddress[msg.sender]);

                        // Decrease the Buyer's Account Balance of tokens by the amount the Sell Offer Order Entry is willing to accept in exchange for ETH
                        balanceEthForAddress[msg.sender] -= totalAmountOfEtherAvailable;

                        // Overflow Checks
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] + volumeAtPriceFromAddress >= tokenBalanceForAddress[msg.sender][tokenNameIndex]);
                        
                        // FIXME - DEBUGGING
                        revert();

                        require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + totalAmountOfEtherAvailable >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who]);

                        // Increase the Buyer's Account Balance of tokens by the amount the Sell Offer Entry is willing to accept in exchange for the ETH
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] += volumeAtPriceFromAddress;
                        // Reset the amount of ETH offered by the Current Sell Order Entry to zero 0
                        tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount = 0;
                         // Increase the Seller's Account Balance of ETH with all the ETH offered by the Current Buy Offer (in exchange for Seller's tokens)
                        balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += totalAmountOfEtherAvailable;
                        tokens[tokenNameIndex].sellBook[whilePrice].offers_key++;

                        BuyOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);

                        amountOfTokensNecessary -= volumeAtPriceFromAddress;
                    } else {
                        require(tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount > amountOfTokensNecessary);

                        totalAmountOfEtherNecessary = amountOfTokensNecessary * whilePrice;

                        // FIXME - DEBUGGING
                        revert();

                        // Overflow Check
                        require(balanceEthForAddress[msg.sender] - totalAmountOfEtherNecessary <= balanceEthForAddress[msg.sender]);

                        balanceEthForAddress[msg.sender] -= totalAmountOfEtherNecessary;

                        // Overflow Check
                        require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + totalAmountOfEtherNecessary >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who]);

                        tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount -= amountOfTokensNecessary;
                        balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += totalAmountOfEtherNecessary;
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] += amountOfTokensNecessary;
                        amountOfTokensNecessary = 0;

                        BuyOrderFulfilled(tokenNameIndex, amountOfTokensNecessary, whilePrice, offers_key);
                    }

                    if (
                        offers_key == tokens[tokenNameIndex].sellBook[whilePrice].offers_length &&
                        tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount == 0
                    ) {
                        tokens[tokenNameIndex].amountSellPrices--;
                        if (whilePrice == tokens[tokenNameIndex].sellBook[whilePrice].higherPrice || tokens[tokenNameIndex].sellBook[whilePrice].higherPrice == 0) {
                            tokens[tokenNameIndex].curSellPrice = 0;
                        } else {
                            tokens[tokenNameIndex].curSellPrice = tokens[tokenNameIndex].sellBook[whilePrice].higherPrice;
                            tokens[tokenNameIndex].sellBook[tokens[tokenNameIndex].sellBook[whilePrice].higherPrice].lowerPrice = 0;
                        }
                    }
                    offers_key++;
                }
                whilePrice = tokens[tokenNameIndex].curSellPrice;
            }

            if (amountOfTokensNecessary > 0) {
                buyToken(symbolName, priceInWei, amountOfTokensNecessary);
            }
        }
    }

    ///////////////////////////
    // BID LIMIT ORDER LOGIC //
    ///////////////////////////

    function addBuyOffer(uint8 tokenIndex, uint priceInWei, uint amount, address who) internal {
        // Offers Length in the Buy Order Book for the Buy Limit Offer Price Entry is increased 
        tokens[tokenIndex].buyBook[priceInWei].offers_length++;

        // Add Buy Offer to Buy Order Book under the Price Offered Entry for a Token Symbol
        tokens[tokenIndex].buyBook[priceInWei].offers[tokens[tokenIndex].buyBook[priceInWei].offers_length] = Offer(amount, who);

        // Update Linked List if the Price Offered Entry does not already exist in the Order Book 
        // - Next Price Entry - Update Lower Price value
        // - Previous Price Entry - Update Higher Price value
        //
        // Note: If it is the First Offer at `priceInWei` in the Buy Order Book 
        // then must inspect Buy Order Book to determine where to Insert the First Offer in the Linked List
        if (tokens[tokenIndex].buyBook[priceInWei].offers_length == 1) {
            tokens[tokenIndex].buyBook[priceInWei].offers_key = 1;
            // New Buy Order Received. Increment Counter. Set later with getOrderBook array
            tokens[tokenIndex].amountBuyPrices++;

            // Set Lower Buy Price and Higher Buy Price for the Token Symbol
            uint curBuyPrice = tokens[tokenIndex].curBuyPrice;
            uint lowestBuyPrice = tokens[tokenIndex].lowestBuyPrice;

            // Case 1 & 2: New Buy Offer is the First Order Entered or Lowest Entry
            if (lowestBuyPrice == 0 || lowestBuyPrice > priceInWei) {
                // Case 1: First Entry. No Orders Exist `lowestBuyPrice == 0`. Insert New (First) Order. Linked List with Single Entry
                if (curBuyPrice == 0) {
                    // Set Current Buy Price to Buy Price of New (First) Order 
                    tokens[tokenIndex].curBuyPrice = priceInWei;
                    // Set Buy Order Book Higher Price to Buy Price of New (First) Order 
                    tokens[tokenIndex].buyBook[priceInWei].higherPrice = priceInWei;
                    // Set Buy Order Book Lower Price to 0 
                    tokens[tokenIndex].buyBook[priceInWei].lowerPrice = 0;
                // Case 2: New Buy Offer is the Lowest Entry (Less Than Lowest Existing Buy Price) `lowestBuyPrice > priceInWei`
                } else {
                    // Set Buy Order Book Lowest Price to New Order Price (Lowest Entry in Linked List)
                    tokens[tokenIndex].buyBook[lowestBuyPrice].lowerPrice = priceInWei;
                    // Adjust Higher and Lower Prices of Linked List relative to New Lowest Entry in Linked List
                    tokens[tokenIndex].buyBook[priceInWei].higherPrice = lowestBuyPrice;
                    tokens[tokenIndex].buyBook[priceInWei].lowerPrice = 0;
                }
                tokens[tokenIndex].lowestBuyPrice = priceInWei;
            }
            // Case 3: New Buy Offer is the Highest Buy Price (Last Entry). Not Need Find Right Entry Location
            else if (curBuyPrice < priceInWei) {
                tokens[tokenIndex].buyBook[curBuyPrice].higherPrice = priceInWei;
                tokens[tokenIndex].buyBook[priceInWei].higherPrice = priceInWei;
                tokens[tokenIndex].buyBook[priceInWei].lowerPrice = curBuyPrice;
                tokens[tokenIndex].curBuyPrice = priceInWei;
            }
            // Case 4: New Buy Offer is between Existing Lowest and Highest Buy Prices. Find Location to Insert Depending on Gas Limit
            else {
                // Start Loop with Existing Highest Buy Price
                uint buyPrice = tokens[tokenIndex].curBuyPrice;
                bool weFoundLocation = false;
                // Loop Until Find
                while (buyPrice > 0 && !weFoundLocation) {
                    if (
                        buyPrice < priceInWei &&
                        tokens[tokenIndex].buyBook[buyPrice].higherPrice > priceInWei
                    ) {
                        // Set New Order Book Entry Higher and Lower Prices of Linked List 
                        tokens[tokenIndex].buyBook[priceInWei].lowerPrice = buyPrice;
                        tokens[tokenIndex].buyBook[priceInWei].higherPrice = tokens[tokenIndex].buyBook[buyPrice].higherPrice;
                        // Set Order Book's Higher Price Entry's Lower Price to the New Offer Current Price
                        tokens[tokenIndex].buyBook[tokens[tokenIndex].buyBook[buyPrice].higherPrice].lowerPrice = priceInWei;
                        // Set Order Books's Lower Price Entry's Higher Price to the New Offer Current Price
                        tokens[tokenIndex].buyBook[buyPrice].higherPrice = priceInWei;
                        // Found Location to Insert New Entry where:
                        // - Higher Buy Prices > Offer Buy Price, and 
                        // - Offer Buy Price > Entry Price
                        weFoundLocation = true;
                    }
                    // Set Highest Buy Price to the Order Book's Highest Buy Price's Lower Entry Price on Each Iteration
                    buyPrice = tokens[tokenIndex].buyBook[buyPrice].lowerPrice;
                }
            }
        }
    }

    function createSellLimitOrderForTokensUnableToMatchWithBuyOrderForSeller(
        string symbolName, uint8 tokenNameIndex, uint priceInWei, uint amountOfTokensNecessary
    ) internal {
        uint totalAmountOfEtherNecessary = 0;
        // Calculate Ether Balance necessary on the Buy-side to Sell all tokens of Token Symbol Name.
        totalAmountOfEtherNecessary = amountOfTokensNecessary * priceInWei;

        // Overflow Check
        require(totalAmountOfEtherNecessary >= amountOfTokensNecessary);
        require(totalAmountOfEtherNecessary >= priceInWei);
        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountOfTokensNecessary);
        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - amountOfTokensNecessary >= 0);
        require(balanceEthForAddress[msg.sender] + totalAmountOfEtherNecessary >= balanceEthForAddress[msg.sender]);

        // Deduct from Exchange Balance the Token amount for the Sell Limit Order
        tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amountOfTokensNecessary;

        // Create New Sell Limit Order in the Sell Order Book if either:
        // - No Buy Orders already exist that match the Sell Price Price Offered by the function caller
        // - Existing Buy Price is less than the Sell Price Offered by the function caller

        // Add Sell Limit Order to Order Book
        addSellOffer(tokenNameIndex, priceInWei, amountOfTokensNecessary, msg.sender);

        // Emit Event
        LimitSellOrderCreated(tokenNameIndex, msg.sender, amountOfTokensNecessary, priceInWei, tokens[tokenNameIndex].sellBook[priceInWei].offers_length);
    }

    /////////////////////////////////
    // NEW ORDER - ASK ORDER       //
    /////////////////////////////////

    // Market Sell Order Function
    // User wants to Sell X-Coins @ Y-Price per coin
    function sellToken(string symbolName, uint priceInWei, uint amount) public payable {
        // Obtain Symbol Index for given Symbol Name
        uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
        uint totalAmountOfEtherNecessary = 0;
        uint totalAmountOfEtherAvailable = 0;
        // Given `amount` Volumne of tokens to find necessary to fulfill the current Sell Order
        uint amountOfTokensNecessary = amount;

        if (tokens[tokenNameIndex].amountBuyPrices == 0 || tokens[tokenNameIndex].curBuyPrice < priceInWei) {
            createSellLimitOrderForTokensUnableToMatchWithBuyOrderForSeller(symbolName, tokenNameIndex, priceInWei, amountOfTokensNecessary);
        } else {
            // Execute Market Sell Order Immediately if:
            // - Existing Buy Limit Order exists that is greater than the Sell Price Offered by the function caller

            // Start with the Highest Buy Price (since Seller wants to exchange their tokens with the highest bidder)
            uint whilePrice = tokens[tokenNameIndex].curBuyPrice;
            uint offers_key;
            // Iterate through the Buy Book (Buy Offers Mapping) to Find "Highest" Buy Offer Prices 
            // (assign to Current Buy Price `whilePrice` each iteration) that are Higher than the Sell Offer
            // and whilst the Volume to find is not yet fulfilled.
            // Note: Since we are in the Sell Order `sellOrder` function we use the Buy Book
            while (whilePrice >= priceInWei && amountOfTokensNecessary > 0) {
                offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
                // Inner While - Iterate Buy Book (Buy Offers Mapping) Entries for the Current Buy Price using FIFO
                while (offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length && amountOfTokensNecessary > 0) {
                    uint volumeAtPriceFromAddress = tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;
                    // Case when Current Buy Order Entry Volume Only Partially fulfills the Sell Order Volume
                    // (i.e. Sell Order wants to sell more than Current Buy Order Entry requires)
                    // then we achieve Partial exchange from Sell Order to the Buy Order Entry and then
                    // move to Next Address with a Buy Order Entry at the Current Buy Price for the symbolName
                    // i.e. Sell Order amount is for 1000 tokens but Current Buy Order is for 500 tokens at Current Buy Price 
                    if (volumeAtPriceFromAddress <= amountOfTokensNecessary) {
                        // Amount of Ether available to be exchanged in the Current Buy Book Offers Entry at the Current Buy Price 
                        totalAmountOfEtherAvailable = volumeAtPriceFromAddress * whilePrice;

                        // Overflow Check
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= volumeAtPriceFromAddress);
                        
                        // Decrease the Seller's Account Balance of tokens by the amount the Buy Offer Order Entry is willing to accept in exchange for ETH
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] -= volumeAtPriceFromAddress;

                        // Overflow Checks
                        // - Assuming the Seller sells a proportion of their `symbolName` tokens in their Sell Offer 
                        //   to the Current Buy Order Entry that is requesting `volumeAtPriceFromAddress` then we need to first
                        //   check that the Sellers account has sufficient Volumne of those tokens to execute the trade
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - volumeAtPriceFromAddress >= 0);
                        // - Check that fulfilling the Current Buy Order Entry by adding the amount of tokens sold by the Sell Offer does not overflow 
                        require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + volumeAtPriceFromAddress >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]);
                        // - Check that fulfilling the Current Buy Order Entry increases the Seller's ETH balance without overflowing 
                        require(balanceEthForAddress[msg.sender] + totalAmountOfEtherAvailable >= balanceEthForAddress[msg.sender]);

                        // Increase the Buyer's Account Balance of tokens (for the matching Buy Order Entry) with the proportion tokens required from the Sell Order
                        // (given that the Buy Offer originator is offering less or equal to the volume of the Sell Offer)
                        tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += volumeAtPriceFromAddress;
                        // Reset the amount of ETH offered by the Current Buy Order Entry to zero 0
                        tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount = 0;
                        // Increase the Seller's Account Balance of ETH with all the ETH offered by the Current Buy Order Entry (in exchange for the Seller's token offering)
                        balanceEthForAddress[msg.sender] += totalAmountOfEtherAvailable;
                        // Move up one element in the Buy Book Offers Mapping (i.e. to the Next Buy Offer at the Current Buy Order Price)
                        tokens[tokenNameIndex].buyBook[whilePrice].offers_key++;

                        // Emit Event
                        SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);

                        // Decrease the amount necessary to be sold from the Seller's Offer by the amount of of tokens just exchanged for ETH with the Buyer at the Current Buy Order Price
                        amountOfTokensNecessary -= volumeAtPriceFromAddress;

                    // Case when Sell Order Volume Only Partially fulfills the Current Buy Order Entry Volume 
                    // (i.e. Sell Order wants to sell more than the Current Buy Order Entry needs)
                    // then we achieve Partial exchange from Sell Order to the Buy Order Entry and then exit
                    // i.e. Sell Order amount is for 500 tokens and Current Buy Order is for 1000 tokens at Current Buy Price 
                    } else {
                        // Check that the equivalent value in tokens of the Buy Offer Order Entry is actually more than Sell Offer Volume 
                        require(volumeAtPriceFromAddress - amountOfTokensNecessary > 0);

                        // Calculate amount in ETH necessary to buy the Seller's tokens based on the Current Buy Price
                        totalAmountOfEtherNecessary = amountOfTokensNecessary * whilePrice;

                        // Overflow Check
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountOfTokensNecessary);

                        // Decrease the Seller's Account Balance of tokens by amount they are offering since the Buy Offer Order Entry is willing to accept it all in exchange for ETH
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amountOfTokensNecessary;

                        // Overflow Check
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountOfTokensNecessary);
                        require(balanceEthForAddress[msg.sender] + totalAmountOfEtherNecessary >= balanceEthForAddress[msg.sender]);
                        require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + amountOfTokensNecessary >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]);

                        // Decrease the Buy Offer Order Entry amount by the full amount necessary to be sold by the Sell Offer
                        tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount -= amountOfTokensNecessary;
                        // Increase the Seller's Account Balance of ETH with the equivalent ETH amount corresponding to that offered by the Current Buy Order Entry (in exchange for the Seller's token offering)
                        balanceEthForAddress[msg.sender] += totalAmountOfEtherNecessary;
                        // Increase the Buyer's Account Balance of tokens (for the matching Buy Order Entry) with all the tokens sold by the Sell Order
                        tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += amountOfTokensNecessary;

                        // Emit Event
                        SellOrderFulfilled(tokenNameIndex, amountOfTokensNecessary, whilePrice, offers_key);

                        // Set the remaining amount necessary to be sold by the Sell Order to zero 0 since we have fulfilled the Sell Offer
                        amountOfTokensNecessary = 0;
                    }

                    // Case when the Current Buy Offer is the last element in the list for the Current Buy Order Offer Price
                    // and when we have exhausted exchanging the Sell Order's amount with Offers at the Current Buy Offer Price
                    // then Move to the Next Highest Buy Order Offer Price in the Buy Book
                    if (
                        offers_key == tokens[tokenNameIndex].buyBook[whilePrice].offers_length &&
                        tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount == 0
                    ) {
                        // Decrease the quantity of Buy Order Prices since we used up the entire volume of all the Buy Offers at that price 
                        tokens[tokenNameIndex].amountBuyPrices--;
                        if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice || tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice == 0) {
                            // Case when no more Buy Book Offers to iterate through for the Current Buy Price (Last element of Linked List) 
                            // then set Current Buy Price to zero 0
                            tokens[tokenNameIndex].curBuyPrice = 0;
                        } else {
                            // REFERENCE "A"
                            // Case when not yet fulfilled `amountOfTokensNecessary` Volume of Sell Offer then
                            // set Proposed Current Buy Price to the Next Lower Buy Price in the Linked List
                            // so we move to the Next Lowest Entry in the Buy Book Offers Linked List
                            tokens[tokenNameIndex].curBuyPrice = tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice;
                            // Set the Higher Price of the Next Lowest Entry that we moved to, to the Current Buy Order Offer Price
                            tokens[tokenNameIndex].buyBook[tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice].higherPrice = tokens[tokenNameIndex].curBuyPrice;
                        }
                    }
                    offers_key++;
                }
                // After Finishing an Iteration of an Entry in the Buy Book Offers (until exhausted all Buy Book Offers for the previous Current Buy Price)
                // and setting the Proposed Current Buy Price to the Next Lowest Buy Price in REFERENCE "A".
                // Move to the Next Lowest Buy Price to be Iterated over by setting the Current Buy Price `whilePrice`
                whilePrice = tokens[tokenNameIndex].curBuyPrice;
            }

            // Case when unable to find a suitable Buy Order Offer to perform an exchange with the Seller's tokens 
            if (amountOfTokensNecessary > 0) {
                // Add a Sell Limit Order to the Sell Book since could not find a Market Order to exchange Seller's tokens immediately

                createSellLimitOrderForTokensUnableToMatchWithBuyOrderForSeller(symbolName, tokenNameIndex, priceInWei, amountOfTokensNecessary);
            }
        }
    }

    ///////////////////////////
    // ASK LIMIT ORDER LOGIC //
    ///////////////////////////

    function addSellOffer(uint8 tokenIndex, uint priceInWei, uint amount, address who) internal {
        // Offers Length in the Sell Order Book for the Sell Limit Offer Price Entry is increased 
        tokens[tokenIndex].sellBook[priceInWei].offers_length++;

        // Add Sell Offer to Sell Order Book under the Price Offered Entry for a Token Symbol
        tokens[tokenIndex].sellBook[priceInWei].offers[tokens[tokenIndex].sellBook[priceInWei].offers_length] = Offer(amount, who);

        if (tokens[tokenIndex].sellBook[priceInWei].offers_length == 1) {
            tokens[tokenIndex].sellBook[priceInWei].offers_key = 1;
            tokens[tokenIndex].amountSellPrices++;
        
            uint curSellPrice = tokens[tokenIndex].curSellPrice;
            uint highestSellPrice = tokens[tokenIndex].highestSellPrice;

            // Case 1 & 2: New Sell Offer is the First Order Entered or Highest Entry  
            if (highestSellPrice == 0 || highestSellPrice < priceInWei) {
                // Case 1: First Entry. No Sell Orders Exist `highestSellPrice == 0`. Insert New (First) Order
                if (curSellPrice == 0) {
                    tokens[tokenIndex].curSellPrice = priceInWei;
                    tokens[tokenIndex].sellBook[priceInWei].higherPrice = 0;
                    tokens[tokenIndex].sellBook[priceInWei].lowerPrice = 0;
                // Case 2: New Sell Offer is the Highest Entry (Higher Than Highest Existing Sell Price) `highestSellPrice < priceInWei`
                } else {
                    tokens[tokenIndex].sellBook[highestSellPrice].higherPrice = priceInWei;
                    tokens[tokenIndex].sellBook[priceInWei].lowerPrice = highestSellPrice;
                    tokens[tokenIndex].sellBook[priceInWei].higherPrice = 0;
                }
                tokens[tokenIndex].highestSellPrice = priceInWei;
            }
            // Case 3: New Sell Offer is the Lowest Sell Price (First Entry). Not Need Find Right Entry Location
            else if (curSellPrice > priceInWei) {
                tokens[tokenIndex].sellBook[curSellPrice].lowerPrice = priceInWei;
                tokens[tokenIndex].sellBook[priceInWei].higherPrice = curSellPrice;
                tokens[tokenIndex].sellBook[priceInWei].lowerPrice = 0;
                tokens[tokenIndex].curSellPrice = priceInWei;
            }
            // Case 4: New Sell Offer is between Existing Lowest and Highest Sell Prices. Find Location to Insert Depending on Gas Limit
            else {
                // Start Loop with Existing Lowest Sell Price
                uint sellPrice = tokens[tokenIndex].curSellPrice;
                bool weFoundLocation = false;
                // Loop Until Find
                while (sellPrice > 0 && !weFoundLocation) {
                    if (
                        sellPrice < priceInWei &&
                        tokens[tokenIndex].sellBook[sellPrice].higherPrice > priceInWei
                    ) {
                        // Set New Order Book Entry Higher and Lower Prices of Linked List
                        tokens[tokenIndex].sellBook[priceInWei].lowerPrice = sellPrice;
                        tokens[tokenIndex].sellBook[priceInWei].higherPrice = tokens[tokenIndex].sellBook[sellPrice].higherPrice;
                        // Set Order Book's Higher Price Entry's Lower Price to the New Offer Current Price
                        tokens[tokenIndex].sellBook[tokens[tokenIndex].sellBook[sellPrice].higherPrice].lowerPrice = priceInWei;
                        // Set Order Books's Lower Price Entry's Higher Price to the New Offer Current Price
                        tokens[tokenIndex].sellBook[sellPrice].higherPrice = priceInWei;
                        // Found Location to Insert New Entry where:
                        // - Lower Sell Prices < Offer Sell Price, and 
                        // - Offer Sell Price < Entry Price
                        weFoundLocation = true;
                    }
                    // Set Lowest Sell Price to the Order Book's Lowest Buy Price's Higher Entry Price on Each Iteration
                    sellPrice = tokens[tokenIndex].sellBook[sellPrice].higherPrice;
                }
            }
        }
    }

    ////////////////////////////////
    // CANCEL ORDER - LIMIT ORDER //
    ////////////////////////////////

    function cancelOrder(string symbolName, bool isSellOrder, uint priceInWei, uint offerKey) public {
        // Retrieve Token Symbol Name Index
        uint8 symbolNameIndex = getSymbolIndexOrThrow(symbolName);

        // Case 1: Cancel Sell Limit Order
        if (isSellOrder) {
            // Verify that Caller Address of Cancel Order Function matches Original Address that Created Sell Limit Order 
            // Note: `offerKey` obtained in front-end logic from Event Emitted at Creation of Sell Limit Order 
            require(tokens[symbolNameIndex].sellBook[priceInWei].offers[offerKey].who == msg.sender);
            // Obtain Tokens Amount that were to be sold in the Sell Limit Order
            uint tokensAmount = tokens[symbolNameIndex].sellBook[priceInWei].offers[offerKey].amount;
            // Overflow Check
            require(tokenBalanceForAddress[msg.sender][symbolNameIndex] + tokensAmount >= tokenBalanceForAddress[msg.sender][symbolNameIndex]);
            // Refund Tokens back to Balance
            tokenBalanceForAddress[msg.sender][symbolNameIndex] += tokensAmount;
            tokens[symbolNameIndex].sellBook[priceInWei].offers[offerKey].amount = 0;
            SellOrderCanceled(symbolNameIndex, priceInWei, offerKey);

        }
        // Case 2: Cancel Buy Limit Order
        else {
            require(tokens[symbolNameIndex].buyBook[priceInWei].offers[offerKey].who == msg.sender);
            uint etherToRefund = tokens[symbolNameIndex].buyBook[priceInWei].offers[offerKey].amount * priceInWei;
            // Overflow Check
            require(balanceEthForAddress[msg.sender] + etherToRefund >= balanceEthForAddress[msg.sender]);
            // Refund Ether back to Balance 
            balanceEthForAddress[msg.sender] += etherToRefund;
            tokens[symbolNameIndex].buyBook[priceInWei].offers[offerKey].amount = 0;
            BuyOrderCanceled(symbolNameIndex, priceInWei, offerKey);
        }
    }
}