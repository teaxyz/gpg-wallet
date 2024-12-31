// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { GPGWalletDeployer } from "src/GPGWalletDeployer.sol";
import { GPGWallet } from "src/GPGWalletImpl.sol";
import { GPGAirdropper } from "src/GPGAirdropper.sol";

contract GPGWalletTest is Test {
    GPGWalletDeployer deployer;
    GPGWallet impl;
    GPGAirdropper airdropper;

    function setUp() public {
        impl = new GPGWallet();
        deployer = new GPGWalletDeployer(address(impl));
        airdropper = new GPGAirdropper(deployer);
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
        GPGWallet wallet = GPGWallet(payable(deployer.deploy(gpgKey)));
        bytes memory key = wallet.publicKey();
        assertEq(gpgKey, key);
    }

    function testAirdropSingle(bytes memory gpgKey) public {
        bytes[] memory keys = new bytes[](1);
        keys[0] = gpgKey;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;

        address[] memory wallets = airdropper.airdrop{value: 1}(keys, amounts);
        assertEq(wallets[0].balance, 1);
    }

    function testAirdropMultiple(bytes[] memory gpgKeys, uint256[] memory amounts) public {
        uint[] memory amounts = new uint[](gpgKeys.length);
        for (uint i = 0; i < gpgKeys.length; i++) {
            amounts[i] = 1;
        }

        address[] memory wallets = airdropper.airdrop{value: gpgKeys.length}(gpgKeys, amounts);
        for (uint i = 0; i < wallets.length; i++) {
            assertEq(wallets[i].balance, 1);
        }
    }

    function testReceive() public {
        address walletAddr = deployer.deploy(new bytes(0));
        (bool success,) = walletAddr.call{value: 1}("");
        require(success);
    }
}
