import React from 'react';
import ReactDOM from 'react-dom';
import { Router, Route, IndexRoute, browserHistory } from 'react-router'
import { Provider } from 'react-redux'
import { syncHistoryWithStore } from 'react-router-redux'
import { DrizzleProvider } from 'drizzle-react'

// Layouts
import App from './App'
import HomeContainer from './layouts/home/HomeContainer'
import LoadingContainer from './layouts/loading/LoadingContainer'

// Contracts
import ERC20Interface from './../build/contracts/ERC20Interface.json'
import Exchange from './../build/contracts/Exchange.json'
import FixedSupplyToken from './../build/contracts/FixedSupplyToken.json'
import owned from './../build/contracts/owned.json'

// Redux Store
import store from './store'

// Initialize react-router-redux.
const history = syncHistoryWithStore(browserHistory, store)

// Set Drizzle options.
const options = {
  web3: {
    block: false,
    fallback: {
      type: 'ws',
      url: 'ws://127.0.0.1:8500'
    }
  },
  contracts: [
    ERC20Interface,
    Exchange,
    FixedSupplyToken,
    owned
  ],
  events: {
    Exchange: [
      'TokenAddedToSystem',
      'DepositForTokenReceived',
      'WithdrawalToken',
      'DepositForEthReceived',
      'WithdrawalEth',
      'LimitBuyOrderCreated',
      'LimitSellOrderCreated',
      'BuyOrderFulfilled',
      'SellOrderFulfilled',
      'BuyOrderCanceled',
      'SellOrderCanceled',
      'Debug'
    ],
    ERC20Interface: [
      'Transfer', 
      'Approval'
    ]
  }
}

ReactDOM.render((
    <DrizzleProvider options={options}>
      <Provider store={store}>
        <LoadingContainer>
          <Router history={history}>
            <Route path="/" component={App}>
              <IndexRoute component={HomeContainer} />
            </Route>
          </Router>
        </LoadingContainer>
      </Provider>
    </DrizzleProvider>
  ),
  document.getElementById('root')
);
