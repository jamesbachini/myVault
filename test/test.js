const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('myVault', () => {

	let myVault;

	beforeEach(async function () {
		const MyVault = await ethers.getContractFactory('myVault');
		[owner, addr1, addr2, ...addrs] = await ethers.getSigners();
		myVault = await MyVault.deploy();
		await myVault.deployed();
  });

	

	it('Should send a transaction', async () => {
		const initialDaiBalance = await myVault.daiBalance();
		console.log('initialDaiBalance', initialDaiBalance);
		const diviTX = await myVault.annualDividend();
		await diviTX.wait();
		const postDaiBalance = await myVault.daiBalance();
		console.log('postDaiBalance', postDaiBalance);
		//expect(await greeter.greet()).to.equal('Hello, world!');
	});
});
