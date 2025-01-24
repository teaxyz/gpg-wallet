// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Script} from "forge-std/Script.sol";
import {DeployHelper} from "./DeployHelper.sol";

contract DeployScript is Script, DeployHelper {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        _deployContracts(true);

        vm.stopBroadcast();
    }
}
