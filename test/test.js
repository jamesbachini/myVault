const hre = require('hardhat');
const assert = require('chai').assert;

describe('myVault', () => {
  let myVault;

  beforeEach(async function () {
    const contractName = 'myVault';
    await hre.run("compile");
    const smartContract = await hre.ethers.getContractFactory(contractName);
    myVault = await smartContract.deploy();
    await myVault.deployed();
    console.log(`${contractName} deployed to: ${myVault.address}`);
  });

  it('Should return the correct version', async () => {
    const version = await myVault.version();
    assert.equal(version,1);
  });

  it('Should return zero DAI balance', async () => {
    const daiBalance = await myVault.getDaiBalance();
    assert.equal(daiBalance,0);
  }); 



  it('Should Rebalance The Portfolio ', async () => {
    const accounts = await hre.ethers.getSigners();
    const owner = accounts[0];
    console.log('Transfering ETH From Owner Address', owner.address);
    await owner.sendTransaction({
      to: myVault.address,
      value: ethers.utils.parseEther('0.01'),
    });
    await myVault.wrapETH();
    await myVault.updateEthPriceUniswap();
    await myVault.rebalance();
    const daiBalance = await myVault.getDaiBalance();
    console.log('Rebalanced DAI Balance',daiBalance.toString());
    assert.isAbove(daiBalance,0);
  });

});
