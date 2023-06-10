import { formatEther } from 'ethers/lib/utils'
import { task } from 'hardhat/config'
import { getConfig, Network, NetworkConfig } from './config'
import { set, ConfigProperty } from '../configManager'

// npx hardhat deploy --verify --network goerli
task('deploy')
  .addFlag('verify', 'verify contracts on etherscan')
  .setAction(async (args, { ethers, run, network }) => {
    try {
      const { verify } = args
      const chainId = network.config.chainId ? network.config.chainId : Network.LOCAL
      const networkConfig: NetworkConfig = getConfig(chainId)

      console.log('Network')
      console.log(network.name)
      console.log('Task Args')
      console.log(args)

      await run('compile')

      // Deploy CharityID contract
      const CharityId = await ethers.getContractFactory('CharityID')
      const charityId = await CharityId.deploy()
      if (verify) {
        await charityId.deployTransaction.wait(5)
        await run('verify:verify', {
          address: charityId.address,
        })
      }
      console.log('CharityID address:', charityId.address)

      set(network.name as any as Network, ConfigProperty.CharityId, charityId.address)

      //Deploy Treasure hunt Contract
      const TreasureHunt = await ethers.getContractFactory('TreasureHunt')
      const treasureHuntArgs: [string] = [charityId.address]
      const treasureHunt = await TreasureHunt.deploy(...treasureHuntArgs)
      if (verify) {
        await treasureHunt.deployTransaction.wait(5)
        await run('verify:verify', {
          address: treasureHunt.address,
          constructorArguments: treasureHuntArgs,
        })
      }
      console.log('Treasure Hunt address:', treasureHunt.address)
      set(network.name as any as Network, ConfigProperty.TreasureHunt, treasureHunt.address)
    } catch (e) {
      console.log('------------------------')
      console.log('FAILED')
      console.error(e)
      console.log('------------------------')
      return 'FAILED'
    }
  })
