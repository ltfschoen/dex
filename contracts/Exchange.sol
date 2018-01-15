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

    ////////////////////////////////
    // DEPOSIT / WITHDRAWAL ETHER //
    ////////////////////////////////

    function depositEther() public payable {
    }

    function withdrawEther(uint amountInWei) public {
    }

    function getEthBalanceInWei() public constant returns (uint) {
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

        // Compare two strings quickly by length to try to avoid detailed loop comparison
        if (a.length != b.length)
            return false;
        
        // Compare two strings in detail Bit-by-Bit
        for (uint i = 0; i < a.length; i++)
            if (a[i] != b[i])
                return false;

        // Byte values of string are the same
        return true;
    }

    ////////////////////////////////
    // DEPOSIT / WITHDRAWAL TOKEN //
    ////////////////////////////////

    function depositToken(string symbolName, uint amount) public {
    }

    function withdrawToken(string symbolName, uint amount) public {
    }

    function getBalance(string symbolName) public constant returns (uint) {
    }

    ///////////////////////////////////
    // ORDER BOOK - BID / ASK ORDERS //
    ///////////////////////////////////

    function getBuyOrderBook(string symbolName) public constant returns (uint[], uint[]) {
    }

    function getSellOrderBook(string symbolName) public constant returns (uint[], uint[]) {
    }

    /////////////////////////////////
    // NEW ORDER - BID / ASK ORDER //
    /////////////////////////////////

    function buyToken(string symbolName, uint priceInWei, uint amount) public {
    }

    function sellToken(string symbolName, uint priceInWei, uint amount) public {
    }

    ////////////////////////////////
    // CANCEL ORDER - LIMIT ORDER //
    ////////////////////////////////

    function cancelOrder(string symbolName, bool isSellOrder, uint priceInWei, uint offerKey) public {
    }
}