// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { GPGWalletDeployer } from "src/GPGWalletDeployer.sol";
import { GPGWallet } from "src/GPGWalletImpl.sol";
import { Airdropper } from "src/Airdropper.sol";

contract AirdropperTest is Test {
    Airdropper airdropper;
    mapping(address => bool) seen;

    function setUp() public {
        address impl = address(new GPGWallet());
        GPGWalletDeployer deployer = new GPGWalletDeployer(impl);
        airdropper = new Airdropper(deployer);
    }

    function testAirdropSingleGPG(bytes memory gpgKey) public {
        bytes[] memory keys = new bytes[](1);
        keys[0] = gpgKey;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;

        address[] memory wallets = airdropper.gpgAirdrop{value: 1}(keys, amounts);
        assertEq(wallets[0].balance, 1);
    }

    function testAirdropSingleEOA(address addr) public {
        vm.assume(uint160(addr) > 10);
        vm.assume(addr.balance == 0);
        vm.assume(addr.code.length == 0);

        address[] memory addresses = new address[](1);
        addresses[0] = addr;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;

        airdropper.eoaAirdrop{value: 1}(addresses, amounts);
        assertEq(addr.balance, 1);
    }

    function testAirdropMultipleGPG(bytes[] memory gpgKeys) public {
        uint[] memory amounts = new uint[](gpgKeys.length);
        for (uint i = 0; i < gpgKeys.length; i++) {
            amounts[i] = 1;
        }

        address[] memory wallets = airdropper.gpgAirdrop{value: gpgKeys.length}(gpgKeys, amounts);
        for (uint i = 0; i < wallets.length; i++) {
            assertEq(wallets[i].balance, 1);
        }
    }

    function testAirdropMultipleEOA(address[] memory addresses) public {
        uint[] memory amounts = new uint[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            vm.assume(uint160(addresses[i]) > uint160(10));
            vm.assume(addresses[i].balance == 0);
            vm.assume(addresses[i].code.length == 0);
            vm.assume(seen[addresses[i]] == false);

            amounts[i] = 1;
            seen[addresses[i]] = true;
        }

        airdropper.eoaAirdrop{value: addresses.length}(addresses, amounts);
        for (uint i = 0; i < addresses.length; i++) {
            assertEq(addresses[i].balance, 1);
        }
    }
}
