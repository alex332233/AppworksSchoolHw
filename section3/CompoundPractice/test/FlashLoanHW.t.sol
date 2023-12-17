// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {AaveFlashLoan} from "../contracts/Aave/FlashLoan.sol";
import {CToken} from "../contracts/CToken.sol";
import {CErc20Delegator} from "../contracts/CErc20Delegator.sol";
import {CErc20Delegate} from "../contracts/CErc20Delegate.sol";
import {Unitroller} from "../contracts/Unitroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Comptroller} from "../contracts/Comptroller.sol";
import {SimplePriceOracle} from "../contracts/SimplePriceOracle.sol";
import {WhitePaperInterestRateModel} from "../contracts/WhitePaperInterestRateModel.sol";

contract FlashLoanHWTest is Test {
    address payable admin_ =
        payable(0xC740E68B06383628c6aB9d046dD23E68EcEec19e);
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");

    ERC20 usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 uni = ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    Comptroller comptroller;
    Unitroller unitroller;
    SimplePriceOracle priceOracle;
    CErc20Delegator cUSDC;
    CErc20Delegator cUNI;
    CErc20Delegate impl;
    WhitePaperInterestRateModel interestRateModel;
    Comptroller comptrollerProxy;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_URL"), 17465000);
        vm.startPrank(admin_);

        comptroller = new Comptroller();
        unitroller = new Unitroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        comptrollerProxy = Comptroller(address(unitroller));

        priceOracle = new SimplePriceOracle();
        comptrollerProxy._setPriceOracle(priceOracle);

        interestRateModel = new WhitePaperInterestRateModel(0, 0);
        impl = new CErc20Delegate();

        cUSDC = new CErc20Delegator(
            address(usdc),
            comptrollerProxy,
            interestRateModel,
            1e6,
            "Compound USDC",
            "cUSDC",
            18,
            admin_,
            address(impl),
            ""
        );
        cUNI = new CErc20Delegator(
            address(uni),
            comptrollerProxy,
            interestRateModel,
            1e18,
            "Compound UNI",
            "cUNI",
            18,
            admin_,
            address(impl),
            ""
        );

        comptrollerProxy._supportMarket(CToken(address(cUSDC)));
        comptrollerProxy._supportMarket(CToken(address(cUNI)));

        comptrollerProxy._setCloseFactor(5e17);
        comptrollerProxy._setLiquidationIncentive(1.08 * 1e18);
        priceOracle.setUnderlyingPrice(CToken(address(cUSDC)), 1e30);
        priceOracle.setUnderlyingPrice(CToken(address(cUNI)), 5e18);
        comptrollerProxy._setCollateralFactor(CToken(address(cUNI)), 5e17);

        vm.stopPrank();

        deal(address(usdc), user1, 5000 * 10 ** 6);
        deal(address(usdc), user2, 5000 * 10 ** 6);
        deal(address(uni), user1, 5000 * 10 ** 18);
        deal(address(uni), user2, 5000 * 10 ** 18);
        deal(address(usdc), address(cUSDC), 5000 * 10 ** 18);
    }

    function testFlashLoan() public {
        vm.startPrank(user1);
        uni.approve(address(cUNI), 1000 * 10 ** 18);
        cUNI.mint(1000 * 10 ** 18);
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cUNI);
        comptrollerProxy.enterMarkets(cTokens);
        cUSDC.borrow(2500 * 10 ** 6);
        assertEq(usdc.balanceOf(user1), 5000 * 10 ** 6 + 2500 * 10 ** 6);
        vm.stopPrank();

        priceOracle.setUnderlyingPrice(CToken(address(cUNI)), 4e18);
        (, , uint256 shortfall) = comptrollerProxy.getAccountLiquidity(user1);
        require(shortfall > 0, "user1 is not undercollateralized");

        vm.startPrank(user2);
        bytes memory params = abi.encode(cUSDC, cUNI, user1);
        uint256 borrowBalance = cUSDC.borrowBalanceStored(user1);
        uint256 liquidateAmount = (borrowBalance * 5e17) / 1e18;

        AaveFlashLoan flashLoan = new AaveFlashLoan();
        flashLoan.flashLoan(address(usdc), liquidateAmount, params);
        flashLoan.withdraw(address(usdc));

        assertGe(usdc.balanceOf(user2), 5063 * 10 ** 6);
        vm.stopPrank();

        console.log("user2 usdc balance: %s", usdc.balanceOf(user2));
    }
}
