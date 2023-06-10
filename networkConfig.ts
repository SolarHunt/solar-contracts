import { ethers } from 'ethers'

export enum Network {
  LOCAL = 1337,
  AVALANCHE = 43114,
  FUJI = 43113,
  POLYGON = 137,
  MUMBAI = 80001,
  GOERLI = 5,
}

export type NetworkConfig = {
  allowedTokenList: {
    [key: string]: {
      address: `0x${string}`
      minTransactionAmount: string
      decimals: number
    }
  }
}

const local: NetworkConfig = {
  allowedTokenList: {
    ETH: {
      address: ethers.constants.AddressZero,
      minTransactionAmount: '0.001',
      decimals: 18,
    },
  },
}

const fuji: NetworkConfig = {
  allowedTokenList: {
    AVAX: {
      address: ethers.constants.AddressZero,
      minTransactionAmount: '0.1',
      decimals: 18,
    },
    USDC: {
      address: '0xAF82969ECF299c1f1Bb5e1D12dDAcc9027431160',
      minTransactionAmount: '1',
      decimals: 6,
    },
  },
}

const mumbai: NetworkConfig = {
  allowedTokenList: {
    MATIC: {
      address: ethers.constants.AddressZero,
      minTransactionAmount: '1',
      decimals: 18,
    },
    USDC: {
      address: '0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747',
      minTransactionAmount: '1',
      decimals: 6,
    },
  },
}

const goerli: NetworkConfig = {
  allowedTokenList: {
    MATIC: {
      address: ethers.constants.AddressZero,
      minTransactionAmount: '1',
      decimals: 18,
    },
    USDC: {
      address: '0xde637d4c445ca2aae8f782ffac8d2971b93a4998',
      minTransactionAmount: '1',
      decimals: 6,
    },
  },
}

const avalanche = {} as NetworkConfig
const polygon: NetworkConfig = {
  allowedTokenList: {
    MATIC: {
      address: ethers.constants.AddressZero,
      minTransactionAmount: '10',
      decimals: 18,
    },
    USDC: {
      address: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
      minTransactionAmount: '10',
      decimals: 6,
    },
    WETH: {
      address: '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
      minTransactionAmount: '0.005',
      decimals: 18,
    },
  },
}

export const configs: { [networkId in Network]: NetworkConfig } = {
  [Network.LOCAL]: local,
  [Network.AVALANCHE]: avalanche,
  [Network.FUJI]: fuji,
  [Network.POLYGON]: polygon,
  [Network.MUMBAI]: mumbai,
  [Network.GOERLI]: local,
}

export const getConfig = (networkId: Network): NetworkConfig => {
  return configs[networkId]
}
