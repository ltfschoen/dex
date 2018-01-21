# Setup 

* Terminal Tab 1 - Install Truffle
  * Reference: http://truffleframework.com/

```
npm install -g truffle
```

* Terminal Tab 2 - Install Test Framework with Ethereum TestRPC

```
npm install -g ganache-cli
```

* Terminal Tab 2 - Start Ethereum Blockchain Protocol Node Simulation

```
ganache-cli --mnemonic "copy obey episode awake damp vacant protect hold wish primary travel shy"
```

* Terminal Tab 1 - Compile and Deploy the FixedSupplyToken Contract

```
truffle migrate --network development
```

* Terminal Tab 1 - Run Sample Unit Tests on the Truffle Contract. Truffle Re-Deploys the Contracts

```
truffle test
```

# Debugging

* Debug the Solidity Smart Contract in Remix IDE
* Verify the Solidity Smart Contract compiles by pasting it in MIST using https://github.com/ltfschoen/geth-node
* Verify the Solidity Smart Contract compiles by deploying it to Ethereum TestRPC using Truffle

# TODO

* [ ] - Incorporate Automated Market Maker (AMM) similar to that described in 0x Whitepaper

# Initial Setup - Truffle, TestRPC, Unit Tests (FixedSupplyContract)

* Install Truffle
  * Reference: http://truffleframework.com/

```
npm install -g truffle
```

* Setup Truffle to Manage Contracts (i.e. MetaCoin sample), Migrations and Unit Tests

```
truffle init

truffle migrate --network development
```

* Initialise with Front-End
  * Truffle Default
    * https://github.com/trufflesuite/truffle-init-default
  * Truffle Webpack
    * https://github.com/trufflesuite/truffle-init-webpack
    * https://github.com/truffle-box/webpack-box
  * Truffle React
    * http://truffleframework.com/boxes/

* Truffle Configuration File Examples
  * http://truffleframework.com/docs/advanced/configuration
  * Note: Use `from` to specify the From Address for Truffle Contract Deployment.
  * Use the Mnemonic to Restart TestRPC with the same Accounts.
  * Note: Use `provider` to specify a Web3 Provider
  * Note: Truffle Build `truffle build` script for say Webpack is usually in package.json

* Truffle with Test Framework using Ethereum TestRPC (avoid delays in mining transactions with Geth Testnet)
  * Ethereum TestRPC - In-Memory Blockchain Simulation

```
npm install -g ganache-cli
```

  * Start Ethereum Blockchain Protocol Node Simulation with 10x Accounts on http://localhost:8500
    * Creates 10x Private Keys and provides a Mnemonic. Assigns to each associated Address 100 Ether.
    * Note: Private Keys may be imported into Metamask Client 
    * Note: Mnemonic may be used subsequently with Ethereum TestRPC to re-create the Accounts with `

```
ganache-cli
```

  * Restart TestRPC with Same Accounts (i.e. `ganache-cli --mnemonic "copy obey episode awake damp vacant protect hold wish primary travel shy"`)

```
ganache-cli --port 8500 --mnemonic <INSERT_MNEMONIC> 
```

* Add FixedSupplyToken to Truffle Contracts folder
* Remove MetaCoin from Truffle Contracts folder
* Update 2nd Migration file to deploy FixedSupplyToken

* Compile and Deploy the FixedSupplyToken Contract

```
truffle migrate --network development
```

* Run Sample Unit Tests on the Truffle MetaCoin Contract. Truffle Re-Deploys the MetaCoin Contracts

```
truffle test
```