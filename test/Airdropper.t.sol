// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GPGWalletDeployer} from "src/GPGWalletDeployer.sol";
import {GPGWallet} from "src/GPGWalletImpl.sol";
import {Airdropper} from "src/Airdropper.sol";

contract AirdropperTest is Test {
    Airdropper airdropper;
    mapping(address => bool) seen;
    mapping(bytes8 => uint256) keyIdToAmount;

    function setUp() public {
        address impl = address(new GPGWallet());
        GPGWalletDeployer deployer = new GPGWalletDeployer(impl);
        airdropper = new Airdropper(deployer);
    }

    function testAirdropSingleGPG(bytes8 keyId) public {
        bytes8[] memory keys = new bytes8[](1);
        keys[0] = keyId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        address[] memory wallets = airdropper.airdropToKeyIds{value: 1}(keys, amounts);
        assertEq(wallets[0].balance, 1);
    }

    function testAirdropSingleEOA(address addr) public {
        vm.assume(uint160(addr) > 10);
        vm.assume(addr.balance == 0);
        vm.assume(addr.code.length == 0);
        vm.assume(addr != 0x000000000000000000636F6e736F6c652e6c6f67);

        address[] memory addresses = new address[](1);
        addresses[0] = addr;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        airdropper.airdropToAddresses{value: 1}(addresses, amounts);
        assertEq(addr.balance, 1);
    }

    function testAirdropMultipleGPG(bytes8[] memory keyIds) public {
        uint256[] memory amounts = new uint256[](keyIds.length);
        for (uint256 i = 0; i < keyIds.length; i++) {
            keyIdToAmount[keyIds[i]] += 1;
            amounts[i] = 1;
        }

        address[] memory wallets = airdropper.airdropToKeyIds{value: keyIds.length}(keyIds, amounts);
        for (uint256 i = 0; i < wallets.length; i++) {
            assertEq(wallets[i].balance, keyIdToAmount[keyIds[i]]);
        }
    }

    function testAirdropMultipleEOA(address[] memory addresses) public {
        uint256[] memory amounts = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            vm.assume(uint160(addresses[i]) > uint160(10));
            vm.assume(addresses[i].balance == 0);
            vm.assume(addresses[i].code.length == 0);
            vm.assume(seen[addresses[i]] == false);
            vm.assume(addresses[i] != 0x000000000000000000636F6e736F6c652e6c6f67);

            amounts[i] = 1;
            seen[addresses[i]] = true;
        }

        airdropper.airdropToAddresses{value: addresses.length}(addresses, amounts);
        for (uint256 i = 0; i < addresses.length; i++) {
            assertEq(addresses[i].balance, 1);
        }
    }

    function testGPGAirdropGas() public {
        uint256 numAirdrops = 400;
        bytes8[] memory keyIds = new bytes8[](numAirdrops);
        uint256[] memory amounts = new uint256[](keyIds.length);
        for (uint256 i = 0; i < keyIds.length; i++) {
            keyIds[i] = bytes8(keccak256(abi.encode(i)));
            amounts[i] = 1;
        }
        uint256 gas = gasleft();
        airdropper.airdropToKeyIds{value: keyIds.length}(keyIds, amounts);
        assertEq(gas - gasleft(), 23663228);
    }

    function testEOAAirdropGas() public {
        uint256 numAirdrops = 750;
        address[] memory addresses = new address[](numAirdrops);
        uint256[] memory amounts = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            addresses[i] = address(uint160(1000 + i));
            amounts[i] = 1;
        }
        uint256 gas = gasleft();
        airdropper.airdropToAddresses{value: addresses.length}(addresses, amounts);
        assertEq(gas - gasleft(), 27367563);
    }
}
