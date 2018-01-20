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
        
        mapping (uint => Offer) offers;
        
        uint offers_key;
        uint offers_length;
    }

    struct Token {
        address tokenContract;
        string symbolName;

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

    function getBuyOrderBook(string symbolName) public constant returns (uint[], uint[]) {
    }

    ///////////////////////////////////
    // ORDER BOOK - ASK ORDERS       //
    ///////////////////////////////////

    function getSellOrderBook(string symbolName) public constant returns (uint[], uint[]) {
    }

    /////////////////////////////////
    // NEW ORDER - BID ORDER       //
    /////////////////////////////////

    function buyToken(string symbolName, uint priceInWei, uint amount) public {
    }

    /////////////////////////////////
    // NEW ORDER - ASK ORDER       //
    /////////////////////////////////

    function sellToken(string symbolName, uint priceInWei, uint amount) public {
    }

    ////////////////////////////////
    // CANCEL ORDER - LIMIT ORDER //
    ////////////////////////////////

    function cancelOrder(string symbolName, bool isSellOrder, uint priceInWei, uint offerKey) public {
    }
}