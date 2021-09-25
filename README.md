# myVault 60/40 Crypto Strategy Vault

This code base was created as part of an intermediate solidity tutorial available here:

https://jamesbachini.com/intermediate-solidity-tutorial/


The idea for the vault is to accept funds and then rebalance back to a 60% ETH 40% DAI stablecoins

Build using the following commands:

```shell
git clone https://github.com/jamesbachini/myVault.git
cd myVault
mv credentials-example.js credentials.js
code credentials.js (Enter Kovan wallet address with funds and Alchemy/Etherscan API Keys)
npm install
npx hardhat compile
npx hardhat node --fork https://eth-kovan.alchemyapi.io/v2/YourAlchemyAPIKeyHere
npx hardhat test --network local
npx hardhat run scripts/deploy.js --network kovan
```

More info and solidity tutorials on my blog at https://jamesbachini.com
