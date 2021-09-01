// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
@title myVault
@license GNU GPLv3
@author James Bachini
@notice A vault to automate and decentralize a long term donation strategy
*/
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

// EACAggregatorProxy is used for chainlink oracle
interface EACAggregatorProxy {
		function latestAnswer() external view returns (int256);
}

// Uniswap v3 interface
interface IUniswapRouter is ISwapRouter {
	function refundETH() external payable;
}

contract myVault {
	uint public version = 1;
	/* Kovan Addresses */
	address public daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
	address public wethAddress = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
	address public usdcAddress = 0xe22da380ee6b445bb8273c81944adeb6e8450422;
	address public payoutAddress = 0x689640212c2DA1E8aB878dA2801d7E09414ffEC8;
	address public uinswapV3QuoterAddress = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
	address public uinswapV3RouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
	address public chainLinkETHUSDAddress = 0x9326BFA02ADD2366b30bacB125260Af641031331;

	/* Mainnet Addresses */

	uint public ethPrice = 0;
	uint public usdTargetPercentage = 40;
	uint public usdDividendPercentage = 25; // 25% of 40% = 10% Annual Drawdown
	uint private dividendFrequency = 5 minutes; // change to 1 years for production
	uint public nextDividendTS;

	using SafeERC20 for IERC20;

	IERC20 daiToken = IERC20(daiAddress);
	IERC20 wethToken = IERC20(wethAddress);
	IQuoter quoter = IQuoter(uinswapV3QuoterAddress);
	IUniswapRouter uniswapRouter = IUniswapRouter (uinswapV3RouterAddress);

	event myVaultLog(string msg, uint ref);

	constructor() {
		console.log('Deploying myVault Version:', version);
		 nextDividendTS = block.timestamp + dividendFrequency;
	}

	function getDaiBalance() public view returns(uint) {
		return daiToken.balanceOf(address(this));
	}

	function getWethBalance() public view returns(uint) {
		return wethToken.balanceOf(address(this));
	}

	function getTotalBalance() public view returns(uint) {
		require(ethPrice > 0, 'ETH price has not been set');
		uint daiBalance = daiToken.balanceOf(address(this));
		uint wethBalance = wethToken.balanceOf(address(this));
		uint wethUSD = wethBalance * ethPrice; // assumes both assets have 18 decimals
		uint totalBalance = wethUSD + daiBalance;
		return totalBalance;
	}

	function annualDividend() public {
		require(block.timestamp > nextDividendTS, 'Dividend is not yet due');
		uint balance = daiToken.balanceOf(address(this));
		uint amount = (balance * usdDividendPercentage) / 100;
		daiToken.safeTransfer(payoutAddress, amount);
		nextDividendTS = block.timestamp + dividendFrequency;
	}

	function updateEthPriceUniswap() public returns(uint) {
		uint ethPriceRaw = quoter.quoteExactOutputSingle(daiAddress,wethAddress,3000,100000,0);
		ethPrice = ethPriceRaw / 100000;
		return ethPrice;
	}

	function updateEthPriceChainlink() public returns(uint) {
		int256 chainLinkEthPrice = EACAggregatorProxy(chainLinkETHUSDAddress).latestAnswer();
		ethPrice = uint(chainLinkEthPrice / 100000000);
		return ethPrice;
	}

	function rebalance() public {
		uint usdBalance = daiToken.balanceOf(address(this));
		uint totalBalance = getTotalBalance();
		uint usdBalancePercentage = 100 * usdBalance / totalBalance;
		emit myVaultLog('usdBalancePercentage', usdBalancePercentage);
		if (usdBalancePercentage < usdTargetPercentage) {
			uint amountToSell = totalBalance / 100 * (usdTargetPercentage - usdBalancePercentage);
			emit myVaultLog('amountToSell', amountToSell);
			require (amountToSell > 0, "Nothing to sell");
			sellWeth(amountToSell);
		} else {
			uint amountToBuy = totalBalance / 100 * (usdBalancePercentage - usdTargetPercentage);
			emit myVaultLog('amountToBuy', amountToBuy);
			require (amountToBuy > 0, "Nothing to buy");
			buyWeth(amountToBuy);
		}
	}

	function buyWeth(uint amountUSD) internal {
		uint256 deadline = block.timestamp + 15;
		uint24 fee = 3000;
		address recipient = address(this);
		uint256 amountIn = amountUSD; // includes 18 decimals
		uint256 amountOutMinimum = 0;
		uint160 sqrtPriceLimitX96 = 0;
		emit myVaultLog('amountIn', amountIn);
		require(daiToken.approve(address(uinswapV3RouterAddress), amountIn), 'DAI approve failed');
		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
			daiAddress,
			wethAddress,
			fee,
			recipient,
			deadline,
			amountIn,
			amountOutMinimum,
			sqrtPriceLimitX96
		);
		uniswapRouter.exactInputSingle(params);
		uniswapRouter.refundETH();
	}

	function sellWeth(uint amountUSD) internal {
		uint256 deadline = block.timestamp + 15;
		uint24 fee = 3000;
		address recipient = address(this);
		uint256 amountOut = amountUSD; // includes 18 decimals
		uint256 amountInMaximum = 10 ** 28 ;
		uint160 sqrtPriceLimitX96 = 0;
		require(wethToken.approve(address(uinswapV3RouterAddress), amountOut), 'WETH approve failed');
		ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
			wethAddress,
			daiAddress,
			fee,
			recipient,
			deadline,
			amountOut,
			amountInMaximum,
			sqrtPriceLimitX96
		);
		uniswapRouter.exactOutputSingle(params);
		uniswapRouter.refundETH();
	}

	function closeAccount() public {
		require(msg.sender == payoutAddress, "Only the payoutAddress can close their account");
		uint daiBalance = daiToken.balanceOf(address(this));
		if (daiBalance > 0) {
			daiToken.safeTransfer(payoutAddress, daiBalance);
		}
		uint wethBalance = wethToken.balanceOf(address(this));
		if (wethBalance > 0) {
			wethToken.safeTransfer(payoutAddress, wethBalance);
		}
	}

	receive() external payable {
		// accept ETH, do nothing as it would break the gas fee for a transaction
	}
}