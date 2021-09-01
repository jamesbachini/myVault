require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

const ethers = require('ethers');
const credentials = require('./credentials.js');

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

task("account", "Print a random account", async (taskArgs, hre) => {
  const wallet = ethers.Wallet.createRandom();
  console.log('Unique Address: ', wallet.address);
  const privateKey = wallet._signingKey().privateKey;
  console.log('Unique privateKey: ', privateKey);
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/${credentials.alchemy}`,
      accounts: [credentials.privateKey],
    },
  },
  etherscan: {
    apiKey: credentials.etherscan
  }
};
