// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import {VmSafe} from "@prb/test/Vm.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {DeterministicDeployer} from "../src/utils/DeterministicDeployer.sol";
import {DeployHelper} from "../src/utils/DeployHelper.sol";

/* solhint-disable max-states-count */
contract BaseTest is PRBTest, StdCheats {
    DeployHelper internal deployHelper;

    VmSafe.Wallet internal initialGovernor = vm.createWallet("Initial Gov Account");
    VmSafe.Wallet internal alice = vm.createWallet("Alice Account");
    VmSafe.Wallet internal bob = vm.createWallet("Bob Account");

    error Unauthorized();
    error AlreadyDeployed();

    function setUp() public virtual {
        vm.createSelectFork({urlOrAlias: "mainnet", blockNumber: 20_456_340});
        bytes32 salt = keccak256(abi.encode(0x00, "tea reward wallet"));
        deployHelper = DeployHelper(
            DeterministicDeployer._deploy(salt, type(DeployHelper).creationCode, abi.encode(initialGovernor.addr, salt))
        );
    }
}
