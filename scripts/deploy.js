const hre = require('hardhat');
const fs = require('fs');

async function main() {
  const contractName = 'myVault';
  await hre.run("compile");
  const smartContract = await hre.ethers.getContractFactory(contractName);
  const smartContract = await MyVault.deploy();
  await smartContract.deployed();
  console.log(`${contractName} deployed to: ${smartContract.address}`);

  const contractArtifacts = artifacts.readArtifactSync(contractName);
  fs.writeFileSync('./artifacts/contractArtifactss.json',  JSON.stringify(contractArtifacts, null, 2));

  await hre.run("verify:verify", {
    address: myVault.address,
    //constructorArguments: [],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
