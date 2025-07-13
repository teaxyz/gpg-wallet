// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseScript} from "../Base.s.sol";
import {DeterministicDeployer} from "../../src/utils/DeterministicDeployer.sol";
import {DeployHelper} from "../../src/utils/DeployHelper.sol";

contract DeployScript is BaseScript {
    function run() public broadcaster {
        string memory seed = vm.readFile("script/system_staged_deploy/data/seed.json");

        address initialGovernor = abi.decode(vm.parseJson(seed, ".initialGovernor"), (address));
        bytes32 salt = abi.decode(vm.parseJson(seed, ".salt"), (bytes32));
        bytes32 salt0 = abi.decode(vm.parseJson(seed, ".salt0"), (bytes32));

        address deployHelper =
            DeterministicDeployer._deploy(salt, type(DeployHelper).creationCode, abi.encode(initialGovernor, salt0));

        string memory deployments = "deployments";
        deployments = vm.serializeAddress(deployments, "deployHelperAddress", deployHelper);

        vm.writeJson(deployments, string.concat("script/system_staged_deploy/data/DeployHelper.json"));
    }
}
