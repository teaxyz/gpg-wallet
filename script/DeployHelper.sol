// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {Airdropper} from "src/Airdropper.sol";
import {GPGRewardWalletDeployer} from "src/GPGRewardWalletDeployer.sol";
import {GPGRewardWallet} from "src/GPGRewardWalletImpl.sol";

contract DeployHelper {
    function _deployContracts(bool log) internal returns (address, GPGRewardWalletDeployer, Airdropper) {
        address impl = address(new GPGRewardWallet());
        GPGRewardWalletDeployer deployer = new GPGRewardWalletDeployer(impl);
        Airdropper airdropper = new Airdropper(deployer);

        assert(deployer.implementation() == impl);
        assert(address(airdropper.deployer()) == address(deployer));

        if (log) {
            console.log("Contracts Deployed:");
            console.log("GPGRewardWalletImpl:", impl);
            console.log("GPGRewardWalletDeployer:", address(deployer));
            console.log("Airdropper:", address(airdropper));
        }

        return (impl, deployer, airdropper);
    }
}
