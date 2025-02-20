// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {Airdropper} from "src/Airdropper.sol";
import {GPGWalletDeployer} from "src/GPGWalletDeployer.sol";
import {AirdropDecoding} from "./AirdropDecoding.sol";
import {DeployHelper} from "./DeployHelper.sol";

contract AirdropScript is Script, AirdropDecoding {
    Airdropper AIRDROPPER = Airdropper(address(1));
    uint256 NUM_KEYID_AIRDROP_FILES = 1;
    uint256 NUM_ADDRESS_AIRDROP_FILES = 1;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // @todo error handling, logging, saving to json, etc
        for (uint256 i; i < NUM_KEYID_AIRDROP_FILES; i++) {
            (bytes8[] memory keyIds, uint256[] memory amounts, uint256 sum) = _getKeyIDAirdropBatch(i);
            address[] memory wallets = AIRDROPPER.airdropToKeyIds{value: sum}(keyIds, amounts);
            for (uint256 j; j < wallets.length; j++) {
                console.log(wallets[j], " deployed for keyId:");
                console.logBytes8(keyIds[j]);
                console.log("********");
            }
        }

        for (uint256 i; i < NUM_ADDRESS_AIRDROP_FILES; i++) {
            (address[] memory addresses, uint256[] memory amounts, uint256 sum) = _getAddressAirdropBatch(i);
            AIRDROPPER.airdropToAddresses{value: sum}(addresses, amounts);
        }

        vm.stopBroadcast();
    }
}
