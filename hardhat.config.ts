import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { config as dotenvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import { resolve } from "path";
import "hardhat-diamond-abi";
import "./tasks/accounts";

import { HoopxFacetList } from "./libs/facets";

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}
const privatekey: string | undefined = process.env.PRIVATE_KEY_NFT_OWNER;
if (!privatekey) {
  throw new Error("Please set your private key in a .env file");
}

const chainIds = {
  mainnet: 1,
  ganache: 1337,
  hardhat: 31337,
  fuji: 43113,
  arbitrum: 42161,
};
function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string;
  switch (chain) {
    case "mainnet":
      jsonRpcUrl = "https://1rpc.io/eth";
      break;
    case "fuji":
      jsonRpcUrl = "https://api.avax-test.network/ext/bc/C/rpc";
      break;
    default:
      jsonRpcUrl = "";
      break;
  }
  return {
    accounts: {
      count: 10,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  };
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  diamondAbi: {
    strict: false,
    name: "DiamondABI",
    include: HoopxFacetList,
    exclude: [],
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
    },
    arbitrum: {
      accounts: [privatekey],
      chainId: chainIds.arbitrum,
      url: "https://arb1.arbitrum.io/rpc",
    },
    ganache: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.ganache,
      url: "http://localhost:8545",
    },
    mainnet: getChainConfig("mainnet"),
    fuji: getChainConfig("fuji"),
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.24",
    settings: {
      evmVersion: "paris",
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
};

export default config;
