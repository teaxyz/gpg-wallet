// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {Airdropper} from "src/Airdropper.sol";
import {GPGWalletDeployer} from "src/GPGWalletDeployer.sol";
import {GPGWallet} from "src/GPGWalletImpl.sol";

contract DeployHelper {
    function _deployContracts(bool log) internal returns (address, GPGWalletDeployer, Airdropper) {
        address impl = address(new GPGWallet());
        GPGWalletDeployer deployer = new GPGWalletDeployer(impl);
        Airdropper airdropper = new Airdropper(deployer);

        assert(deployer.implementation() == impl);
        assert(address(airdropper.deployer()) == address(deployer));

        if (log) {
            console.log("Contracts Deployed:");
            console.log("GPGWalletImpl:", impl);
            console.log("GPGWalletDeployer:", address(deployer));
            console.log("Airdropper:", address(airdropper));
        }

        return (impl, deployer, airdropper);
    }
}
