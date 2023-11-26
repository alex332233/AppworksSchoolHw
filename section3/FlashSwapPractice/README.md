# Flash Swap Practice
This is a UniswapV2 flash swap practice, our goal is to pass the test.

### Practice 1: `Liquidator.sol`
`liquidate()` will call `FakeLendingProtocol.liquidatePosition()` to liquidate the position of the user.
Follow the instructions in `contracts/Liquidator.sol` to complete the practice.
(Do not change any other files)

### Practice 2: `Arbitrage.sol`
`arbitrage()` will do the arbitrage between the given two pools (must be the same pair).
Follow the instructions in `contracts/Arbitrage.sol` to complete the practice.
For convenience, we will only practice method 1, and fix the borrowed amount to 5 WETH

If you are interested in the flash swap arbitrage, you can read more in this [repository](https://github.com/paco0x/amm-arbitrageur)

## Local Development
Clone this repository, install Node.js dependencies, and build the source code:

```bash
git clone git@github.com:AppWorks-School/Blockchain-Resource.git
cd Blockchain-Resource/section3/FlashSwapPractice
npm install
forge install
forge build
forge test
```

# Flash Swap Practice Homework explanation
## `Arbitrage.sol`
### 1.get pair
1)Get pair from priceLowerPool with IUniswapV2Pair token0 and token1 function.
2)Get reserves from priceLowerPool with IUniswapV2Pair getReserves function.
### 2.calculate repay amount, and set callback data
1)Use built in (copy from UniswapV2Library) _getAmountIn function to calculate repayAmount.
2)Set callbackdata for uniswapV2Call.
### 3.borrow WETH from lower price pool and go into uniswapV2Call
Use IUniswapV2Pair swap function.
### 4.decode callback data into CallbackData Struct and approve borrowAmount WETH to higher price pool
### 5.swap borrowAmount WETH and get USDC amountOut
1)Get reserves from priceHigherPool with IUniswapV2Pair getReserves function.
2)Transfer borrowAmount WETH to priceHigherPool.
3)Use built in (copy from UniswapV2Library) _getAmountOut function to calculate swap USDC amount.
4)Repay USDC to priceLowerPool with transfer function.
