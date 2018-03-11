import React, { Component, Children } from 'react'
import net from 'net';
import Web3 from 'web3';

class Loading extends Component {
  constructor(props, context) {
    super(props)
  }

  render() {
    if (this.props.web3.status === 'failed')
    {
      return(
        <main className="container loading-screen">
          <div className="pure-g">
            <div className="pure-u-1-1">
              <h1>⚠️</h1>
              <p>This browser has no connection to the Ethereum network. Please use the Chrome/FireFox extension MetaMask, or dedicated Ethereum browsers Mist or Parity.</p>
            </div>
          </div>
        </main>
      )
    }

    if (this.props.drizzleStatus.initialized)
    {
      return Children.only(this.props.children)
    }

    console.log("accounts: ", this.props.accounts);
    console.log("contracts: ", this.props.contracts);
    console.log("drizzleStatus: ", this.props.drizzleStatus);
    console.log("web3: ", this.props.web3);
    console.log("Rinkeby Testnet URL: ", process.env.REACT_APP_INFURA_RINKEBY_TESTNET_URL)
    const web3 = new Web3(process.env.REACT_APP_INFURA_ROPSTEN_TESTNET_URL, net);
    console.log(web3)

    return(
      <main className="container loading-screen">
        <div className="pure-g">
          <div className="pure-u-1-1">
            <h1>⚙️</h1>
            <p>Loading dapp...</p>
          </div>
        </div>
      </main>
    )
  }
}

export default Loading
