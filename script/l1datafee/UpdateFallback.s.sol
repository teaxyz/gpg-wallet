// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script, console } from "forge-std/Script.sol";
import { IGasPriceOracle } from "./IGasPriceOracle.sol";

contract UpdateFallback is Script {
    IGasPriceOracle constant GAS_PRICE_ORACLE = IGasPriceOracle(0x420000000000000000000000000000000000000F);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        GAS_PRICE_ORACLE.setFallbackPrice(1_000_000e18);

        // It shouldn't update until the next system tx.
        (, uint160 latestPrice) = GAS_PRICE_ORACLE.getLatestPrice();
        require(latestPrice == 1_500_000e18);

        vm.stopBroadcast();
    }
}
