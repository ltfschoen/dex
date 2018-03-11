import Home from './Home'
import { drizzleConnect } from 'drizzle-react'

// May still need this even with data function to refresh component on updates for this contract.
const mapStateToProps = state => {
  return {
    accounts: state.accounts,
    ERC20Interface: state.contracts.ERC20Interface,
    Exchange: state.contracts.Exchange,
    FixedSupplyToken: state.contracts.FixedSupplyToken,
    owned: state.contracts.owned,
    drizzleStatus: state.drizzleStatus
  }
}

const HomeContainer = drizzleConnect(Home, mapStateToProps);

export default HomeContainer
