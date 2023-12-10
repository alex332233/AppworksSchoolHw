//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../scripts/CompoundHW.s.sol";

contract CompoundHWTest is Test, MyScript {
    address admin = makeAddr("Admin");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");

    function setUp() public {
        vm.startPrank(admin);
        run();
        vm.stopPrank();
        deal(address(tokenA), user1, 100 * 10 ** 18);
        deal(address(tokenA), user2, 100 * 10 ** 18);
        deal(address(tokenB), user1, 100 * 10 ** 18);
        deal(address(tokenB), user2, 100 * 10 ** 18);
    }

    function testMintRedeem() public {
        // HW case2
        vm.startPrank(user1);
        tokenA.approve(address(cTokenA), 100 * 10 ** 18);
        cTokenA.mint(100 * 10 ** 18);
        assertEq(tokenA.balanceOf(user1), 0);
        assertEq(cTokenA.balanceOf(user1), 100 * 10 ** 18);
        cTokenA.redeem(100 * 10 ** 18);
        assertEq(tokenA.balanceOf(user1), 100 * 10 ** 18);
        assertEq(cTokenA.balanceOf(user1), 0);
        vm.stopPrank();
    }

    function testBorrow() public {
        // HW case3
        // set initial tokenA balance
        deal(address(tokenA), address(cTokenA), 100 * 10 ** 18);

        // user1 deposit 1tokenB to borrow 50 tokenA
        vm.startPrank(user1);
        tokenB.approve(address(cTokenB), 1 * 10 ** 18);
        cTokenB.mint(1 * 10 ** 18);
        assertEq(tokenB.balanceOf(user1), 99 * 10 ** 18);
        assertEq(cTokenB.balanceOf(user1), 1 * 10 ** 18);
        // remember to enter market = enable tokenB as collateral
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cTokenB);
        Comptroller(address(unitroller)).enterMarkets(cTokens);
        cTokenA.borrow(50 * 10 ** 18);
        assertEq(tokenA.balanceOf(address(cTokenA)), 50 * 10 ** 18);
        assertEq(tokenA.balanceOf(user1), 150 * 10 ** 18);
        vm.stopPrank();
    }

    function testLiquidateScene1() public {
        // HW case4
        borrowTokenA();

        // adjust collateral factor to 25%
        vm.startPrank(admin);
        Comptroller(address(unitroller))._setCollateralFactor(
            CToken(address(cTokenB)),
            25e16
        );
        vm.stopPrank();

        // user2 liquidate user1
        vm.startPrank(user2);
        (, , uint256 shortfall) = Comptroller(address(unitroller))
            .getAccountLiquidity(user1);
        require(shortfall > 0, "user1 is not undercollateralized");
        tokenA.approve(address(cTokenA), 100 * 10 ** 18);
        // execute liquidation
        uint256 borrowBalance = cTokenA.borrowBalanceStored(user1);
        uint256 liquidateAmount = (borrowBalance * 25e16) / 1e18;
        cTokenA.liquidateBorrow(user1, liquidateAmount, cTokenB);
        assertEq(tokenA.balanceOf(user2), 100 * 10 ** 18 - liquidateAmount);
        // Calculate Seize Tokens
        (, uint256 seizeTokens) = Comptroller(address(unitroller))
            .liquidateCalculateSeizeTokens(
                address(cTokenA),
                address(cTokenB),
                liquidateAmount
            );
        uint256 receivecTokenBAmount = (seizeTokens *
            (1e18 - cTokenA.protocolSeizeShareMantissa())) / 1e18;
        assertEq(cTokenB.balanceOf(user2), receivecTokenBAmount);
        vm.stopPrank();
    }

    function borrowTokenA() public {
        // set initial tokenA balance
        deal(address(tokenA), address(cTokenA), 100 * 10 ** 18);

        // user1 deposit 1tokenB to borrow 50 tokenA
        vm.startPrank(user1);
        tokenB.approve(address(cTokenB), 1 * 10 ** 18);
        cTokenB.mint(1 * 10 ** 18);
        assertEq(tokenB.balanceOf(user1), 99 * 10 ** 18);
        assertEq(cTokenB.balanceOf(user1), 1 * 10 ** 18);
        // remember to enter market = enable tokenB as collateral
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cTokenB);
        Comptroller(address(unitroller)).enterMarkets(cTokens);
        cTokenA.borrow(50 * 10 ** 18);
        assertEq(tokenA.balanceOf(address(cTokenA)), 50 * 10 ** 18);
        assertEq(tokenA.balanceOf(user1), 150 * 10 ** 18);
        vm.stopPrank();
    }

    function testLiquidateScene2() public {
        // HW case5
        borrowTokenA();

        // adjust cTokenB price to 30USD
        vm.startPrank(admin);
        priceOracle.setUnderlyingPrice(CToken(address(cTokenB)), 30e18);
        vm.stopPrank();

        // user2 liquidate user1
        vm.startPrank(user2);
        (, , uint256 shortfall) = Comptroller(address(unitroller))
            .getAccountLiquidity(user1);
        require(shortfall > 0, "user1 is not undercollateralized");
        tokenA.approve(address(cTokenA), 100 * 10 ** 18);
        // execute liquidation
        uint256 borrowBalance = cTokenA.borrowBalanceStored(user1);
        uint256 liquidateAmount = (borrowBalance - 30e18);
        cTokenA.liquidateBorrow(user1, liquidateAmount, cTokenB);
        assertEq(tokenA.balanceOf(user2), 100 * 10 ** 18 - liquidateAmount);
        // Calculate Seize Tokens
        (, uint256 seizeTokens) = Comptroller(address(unitroller))
            .liquidateCalculateSeizeTokens(
                address(cTokenA),
                address(cTokenB),
                liquidateAmount
            );
        uint256 receivecTokenBAmount = ((seizeTokens *
            (1e18 - cTokenA.protocolSeizeShareMantissa())) / 1e18);
        assertEq(cTokenB.balanceOf(user2), receivecTokenBAmount);
        vm.stopPrank();
    }
}
