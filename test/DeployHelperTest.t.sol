// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {BaseTest} from "./BaseTest.t.sol";
import {Airdropper} from "../src/Airdropper.sol";
import {GPGRewardWalletDeployer} from "../src/GPGRewardWalletDeployer.sol";
import {GPGRewardWallet} from "../src/GPGRewardWalletImpl.sol";

contract DeployHelperTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_deploy_reverts_Unauthorized() public {
        vm.expectRevert(BaseTest.Unauthorized.selector);
        deployHelper.deploy(keccak256("salt1"), keccak256("salt2"));
    }

    function test_deploy_reverts_AlreadyDeployed() public {
        vm.startPrank(initialGovernor.addr);

        deployHelper.deploy(keccak256("salt1"), keccak256("salt2"));
        vm.expectRevert(BaseTest.AlreadyDeployed.selector);
        deployHelper.deploy(keccak256("salt3"), keccak256("salt4"));

        vm.stopPrank();
    }

    function test_deployed_state() public {
        vm.startPrank(initialGovernor.addr);

        deployHelper.deploy(keccak256("salt1"), keccak256("salt2"));

        assertEq(deployHelper.INITIAL_GOVERNOR(), initialGovernor.addr);
        assertNotEq(deployHelper.IMPLEMENTATION(), address(0));

        bytes32 airDropperCodeHash = keccak256(
            abi.encodePacked(
                type(Airdropper).creationCode, abi.encode(deployHelper.deployer(), deployHelper.INITIAL_GOVERNOR())
            )
        );
        assertEq(
            address(deployHelper.airdropper()),
            Create2.computeAddress(keccak256("salt2"), airDropperCodeHash, address(deployHelper))
        );

        bytes32 deployerCodeHash = keccak256(
            abi.encodePacked(type(GPGRewardWalletDeployer).creationCode, abi.encode(deployHelper.IMPLEMENTATION()))
        );
        assertEq(
            address(deployHelper.deployer()),
            Create2.computeAddress(keccak256("salt1"), deployerCodeHash, address(deployHelper))
        );

        bytes32 implementationCodeHash =
            keccak256(abi.encodePacked(type(GPGRewardWallet).creationCode, abi.encode(deployHelper.INITIAL_GOVERNOR())));
        assertEq(
            address(deployHelper.IMPLEMENTATION()),
            Create2.computeAddress(
                keccak256(abi.encode(0x00, "tea reward wallet")), implementationCodeHash, address(deployHelper)
            )
        );
    }
}
