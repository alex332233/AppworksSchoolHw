// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
// import { TestERC20 } from "../contracts/test/TestERC20.sol";
// import { SimpleSwap } from "../contracts/SimpleSwap.sol";
import {CErc20Delegator} from "../contracts/CErc20Delegator.sol";
// import {} "../contracts/CTokenInterfaces.sol";
// import "../contracts/ComptrollerInterface.sol";
// import "../contracts/InterestRateModel.sol";
// import "../contracts/ErrorReporter.sol";
// import "../contracts/EIP20NonStandardInterface.sol";
import {CErc20Delegate} from "../contracts/CErc20Delegate.sol";
import {Unitroller} from "../contracts/Unitroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {USDT} from "../contracts/USDT.sol";
import {AlexErc20} from "../contracts/AlexErc20.sol";
import {Comptroller} from "../contracts/Comptroller.sol";
import {ComptrollerInterface} from "../contracts/ComptrollerInterface.sol";
import {SimplePriceOracle} from "../contracts/SimplePriceOracle.sol";
import {WhitePaperInterestRateModel} from "../contracts/WhitePaperInterestRateModel.sol";

contract MyScript is Script {
    function run() external {
        vm.startBroadcast();
        // deployment parameters
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // string memory rpcUrl = vm.envString("RPC_URL");

        // Deploying Comptroller
        Comptroller comptroller = new Comptroller();
        Unitroller unitroller = new Unitroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        // Deploying PriceOracle
        SimplePriceOracle priceOracle = new SimplePriceOracle();
        Comptroller comptrollerOracle = Comptroller(address(unitroller));
        comptrollerOracle._setPriceOracle(priceOracle);

        // delegator parameters
        // address underlying_ = address(new USDT());
        ERC20 erc20Token = new AlexErc20();
        address underlying_ = address(erc20Token);
        ComptrollerInterface comptroller_ = ComptrollerInterface(
            address(unitroller)
        );

        WhitePaperInterestRateModel interestRateModel_ = new WhitePaperInterestRateModel(
                0,
                0
            );
        uint initialExchangeRateMantissa_ = 1e18;
        // string memory name_ = "Compound USDT";
        // string memory symbol_ = "cUSDT";
        string memory name_ = "Compound AlexErc20";
        string memory symbol_ = "cAE2";
        uint8 decimals_ = 18;
        address payable admin_ = payable(
            0xC740E68B06383628c6aB9d046dD23E68EcEec19e
        );
        address implementation_ = address(new CErc20Delegate());
        bytes memory becomeImplementationData = "";

        // TestERC20 tokenA = new TestERC20("tokenA", "TKA");
        // TestERC20 tokenB = new TestERC20("tokenB", "TKB");
        // SimpleSwap simpleSwap = new SimpleSwap(
        //     address(tokenA),
        //     address(tokenB)
        // );
        CErc20Delegator cerc20delegator = new CErc20Delegator(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_,
            implementation_,
            becomeImplementationData
        );
        vm.stopBroadcast();
        console.log("Compound address: %s", address(cerc20delegator));
    }
}
