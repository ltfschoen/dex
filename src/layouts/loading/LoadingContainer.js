import Loading from './Loading.js'
import { drizzleConnect } from 'drizzle-react'

// May still need this even with data function to refresh component on updates for this contract.
// Define web3 in mapStateToProps function of container component
const mapStateToProps = (state, props) => {
  return {
    drizzleStatus: state.drizzleStatus,
    web3: state.web3
  }
}

console.log(process.env.NODE_ENV)

const LoadingContainer = drizzleConnect(Loading, mapStateToProps);

export default LoadingContainer
