const hre = require('hardhat');
const fs = require('fs');

async function main() {
  const contractName = 'myVault';
  await hre.run("compile");
  const smartContract = await hre.ethers.getContractFactory(contractName);
  const myVault = await smartContract.deploy();
  await myVault.deployed();
  console.log(`${contractName} deployed to: ${myVault.address}`);

  const contractArtifacts = await artifacts.readArtifactSync(contractName);
  fs.writeFileSync('./artifacts/contractArtifacts.json',  JSON.stringify(contractArtifacts, null, 2));

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
