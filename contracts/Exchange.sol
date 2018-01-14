pragma solidity ^0.4.18;

import "./owned.sol";
import "./FixedSupplyToken.sol";

contract Exchange is owned {

    ///////////////////////
    // GENERAL STRUCTURE //
    ///////////////////////

    struct Offer {
    }

    struct OrderBook {
    }

    struct Token {
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

    function depositEther() payable {
    }

    function withdrawEther(uint amountInWei) {
    }

    function getEthBalanceInWei() constant returns (uint) {
    }

    //////////////////////
    // TOKEN MANAGEMENT //
    //////////////////////

    function addToken(string symbolName, address erc20TokenAddress) onlyowner {
    }

    function hasToken(string symbolName) constant returns (bool) {
    }


    function getSymbolIndex(string symbolName) internal returns (uint8) {
    }

    ////////////////////////////////
    // DEPOSIT / WITHDRAWAL TOKEN //
    ////////////////////////////////

    function depositToken(string symbolName, uint amount) {
    }

    function withdrawToken(string symbolName, uint amount) {
    }

    function getBalance(string symbolName) constant returns (uint) {
    }

    ///////////////////////////////////
    // ORDER BOOK - BID / ASK ORDERS //
    ///////////////////////////////////

    function getBuyOrderBook(string symbolName) constant returns (uint[], uint[]) {
    }

    function getSellOrderBook(string symbolName) constant returns (uint[], uint[]) {
    }

    /////////////////////////////////
    // NEW ORDER - BID / ASK ORDER //
    /////////////////////////////////

    function buyToken(string symbolName, uint priceInWei, uint amount) {
    }

    function sellToken(string symbolName, uint priceInWei, uint amount) {
    }

    ////////////////////////////////
    // CANCEL ORDER - LIMIT ORDER //
    ////////////////////////////////

    function cancelOrder(string symbolName, bool isSellOrder, uint priceInWei, uint offerKey) {
    }
}