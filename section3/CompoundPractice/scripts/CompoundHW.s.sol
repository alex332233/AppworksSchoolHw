// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CErc20Delegator} from "../contracts/CErc20Delegator.sol";
import {CErc20Delegate} from "../contracts/CErc20Delegate.sol";
import {Unitroller} from "../contracts/Unitroller.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AlexErc20, AlexErc20TokenB} from "../contracts/AlexErc20.sol";
import {Comptroller} from "../contracts/Comptroller.sol";
import {ComptrollerInterface} from "../contracts/ComptrollerInterface.sol";
import {SimplePriceOracle} from "../contracts/SimplePriceOracle.sol";
import {WhitePaperInterestRateModel} from "../contracts/WhitePaperInterestRateModel.sol";
import {CToken} from "../contracts/CToken.sol";

contract MyScript is Script {
    ERC20 public tokenA;
    ERC20 public tokenB;
    CErc20Delegator cTokenA;
    CErc20Delegator cTokenB;
    Unitroller unitroller;
    SimplePriceOracle priceOracle;

    function run() public {
        // vm.startBroadcast(); // for real network
        // deployment parameters
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // string memory rpcUrl = vm.envString("RPC_URL");

        // Deploying Comptroller
        Comptroller comptroller = new Comptroller();
        unitroller = new Unitroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        // Deploying Comptroller Prxoy
        Comptroller comptrollerProxy = Comptroller(address(unitroller));

        // Deploying PriceOracle
        priceOracle = new SimplePriceOracle();
        comptrollerProxy._setPriceOracle(priceOracle);

        // delegator parameters
        tokenA = new AlexErc20();
        tokenB = new AlexErc20TokenB();
        // ERC20 erc20Token = new AlexErc20();
        address underlyingA_ = address(tokenA);
        address underlyingB_ = address(tokenB);
        ComptrollerInterface comptroller_ = ComptrollerInterface(
            address(unitroller)
        );

        WhitePaperInterestRateModel interestRateModel_ = new WhitePaperInterestRateModel(
                0,
                0
            );
        uint initialExchangeRateMantissa_ = 1e18;
        string memory nameA_ = "Compound AlexErc20";
        string memory nameB_ = "Compound AlexErc20TokenB";
        string memory symbolA_ = "cAE2";
        string memory symbolB_ = "cAE2B";
        uint8 decimals_ = 18;
        address payable admin_ = payable(
            0xC740E68B06383628c6aB9d046dD23E68EcEec19e
        );
        address implementation_ = address(new CErc20Delegate());
        bytes memory becomeImplementationData = "";

        cTokenA = new CErc20Delegator(
            underlyingA_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            nameA_,
            symbolA_,
            decimals_,
            admin_,
            implementation_,
            becomeImplementationData
        );
        cTokenB = new CErc20Delegator(
            underlyingB_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            nameB_,
            symbolB_,
            decimals_,
            admin_,
            implementation_,
            becomeImplementationData
        );

        // add Market to Markets
        comptrollerProxy._supportMarket(CToken(address(cTokenA)));
        comptrollerProxy._supportMarket(CToken(address(cTokenB)));

        // set tokenA and tokenB price
        priceOracle.setUnderlyingPrice(CToken(address(cTokenA)), 1e18); // 1USD
        priceOracle.setUnderlyingPrice(CToken(address(cTokenB)), 1e20); // 100USD

        // set collateralFactor, closeFactor, liquidationIncentive
        comptrollerProxy._setCollateralFactor(CToken(address(cTokenB)), 5e17); // 50%
        comptrollerProxy._setCloseFactor(5e17); // 50%
        comptrollerProxy._setLiquidationIncentive(1.08 * 1e18); // 8%

        // vm.stopBroadcast(); // for real network
        console.log("cTokenA address: %s", address(cTokenA));
        console.log("cTokenB address: %s", address(cTokenB));
    }
}
