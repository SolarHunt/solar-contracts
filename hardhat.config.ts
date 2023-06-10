import type { HardhatUserConfig } from 'hardhat/config'
import type { NetworkUserConfig } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'
import '@nomicfoundation/hardhat-toolbox'
import 'hardhat-contract-sizer'
import './scripts/deploy'
import './scripts/wallet'
import { Network } from './scripts/config'
import { get } from 'http'

dotenvConfig({ path: resolve(__dirname, './.env') })

const mnemonic: string | undefined = process.env.MNEMONIC
if (!mnemonic) {
  throw new Error('Please set your MNEMONIC in a .env file')
}

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY
if (!infuraApiKey) {
  throw new Error('Please set your INFURA_API_KEY in a .env file')
}

function getChainConfig(chain: Network): NetworkUserConfig {
  let jsonRpcUrl: string
  switch (chain) {
    case Network.MAINNET:
      jsonRpcUrl = 'https://mainnet.infura.io/v3/' + infuraApiKey
      break
    case Network.SEPOLIA:
      jsonRpcUrl = 'https://sepolia.infura.io/v3/' + infuraApiKey
      break
    case Network.GNOSIS:
      jsonRpcUrl = 'https://rpc.ankr.com/gnosis'
      break
    case Network.GOERLI:
      jsonRpcUrl = 'https://rpc.eu-central-2.gateway.fm/v4/gnosis/non-archival/mainnet'
      break
    case Network.KOVAN:
      jsonRpcUrl = 'https://kovan.infura.io/v3/' + infuraApiKey
      break
    case Network.MUMBAI:
      jsonRpcUrl = 'https://polygon-mumbai.infura.io/v3/' + infuraApiKey
      break
    case Network.MANTLETESTNET:
      jsonRpcUrl = 'https://rpc.testnet.mantle.xyz/'
      // https://rpc.mantle.xyz
      break
    default:
      jsonRpcUrl = 'https://mainnet.infura.io/v3/' + infuraApiKey
  }

  return {
    accounts: {
      count: 10,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chain,
    url: jsonRpcUrl,
  }
}

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || '',
      xdai: process.env.GNOSIS_API_KEY || '',
      goerli: process.env.ETHERSCAN_API_KEY || '',
      kovan: process.env.ETHERSCAN_API_KEY || '',
      sepolia: process.env.ETHERSCAN_API_KEY || '',
      mantletestnet: process.env.MANTLE_API_KEY || '',
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || '',
    },
  },
  gasReporter: {
    currency: 'USD',
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    enabled: process.env.REPORT_GAS ? true : false,
    showTimeSpent: true,
    excludeContracts: [],
    src: './contracts',
    // noColors: true,
    // outputFile: "./reports/LoadTest",
  },

  networks: {
    hardhat: {
      accounts: {
        mnemonic,
        count: 100,
      },
      chainId: Network.LOCAL,
    },
    mainnet: getChainConfig(Network.MAINNET),
    goerli: getChainConfig(Network.GOERLI),
    gnosis: getChainConfig(Network.GNOSIS),
    kovan: getChainConfig(Network.KOVAN),
    sepolia: getChainConfig(Network.SEPOLIA),
    mumbai: getChainConfig(Network.MUMBAI),
    mantletestnet: getChainConfig(Network.MANTLETESTNET),
  },
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './test',
  },
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.5.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  mocha: {
    timeout: 1000000,
  },
}

export default config
