// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { GPGWalletDeployer } from "src/GPGWalletDeployer.sol";
import { GPGWallet } from "src/GPGWalletImpl.sol";

contract GPGWalletTest is Test {
    GPGWalletDeployer deployer;
    GPGWallet impl;

    function setUp() public {
        impl = new GPGWallet();
        deployer = new GPGWalletDeployer(address(impl));
    }

    function testPredictAddress(bytes memory gpgKey) public {
        (address predictedBefore, bool deployedBefore) = deployer.predictAddress(gpgKey);
        address wallet = deployer.deploy(gpgKey);
        (address predictedAfter, bool deployedAfter) = deployer.predictAddress(gpgKey);

        assertEq(predictedBefore, wallet);
        assertEq(predictedAfter, wallet);

        assertEq(deployedBefore, false);
        assertEq(deployedAfter, true);
    }

    function testReadPubKey(bytes memory gpgKey) public {
        GPGWallet wallet = GPGWallet(deployer.deploy(gpgKey));
        bytes memory key = wallet.publicKey();
        assertEq(gpgKey, key);
    }

    function testBatchDeploy(bytes[] memory gpgKeys) public {
        address[] memory wallets = deployer.batchDeploy(gpgKeys);
        assertEq(wallets.length, gpgKeys.length);

        for (uint256 i = 0; i < wallets.length; i++) {
            GPGWallet wallet = GPGWallet(wallets[i]);
            bytes memory key = wallet.publicKey();
            assertEq(gpgKeys[i], key);
        }
    }
}
