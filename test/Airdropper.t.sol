// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {BaseTest} from "./BaseTest.t.sol";
import {Airdropper} from "../src/Airdropper.sol";
import {GPGRewardWalletDeployer} from "../src/GPGRewardWalletDeployer.sol";
import {GPGRewardWallet} from "../src/GPGRewardWalletImpl.sol";

contract AirdropperTest is BaseTest {
    Airdropper internal airdropper;

    function setUp() public virtual override {
        super.setUp();

        vm.prank(initialGovernor.addr);
        deployHelper.deploy(keccak256("salt1"), keccak256("salt2"));

        airdropper = Airdropper(deployHelper.airdropper());
    }

    /// Test reverts if the caller is not the governor
    function test_revert_if_not_governor() public {
        vm.expectRevert(Airdropper.Unauthorized.selector);
        airdropper.prepareDrop(new bytes8[](0), new uint256[](0));
    }

    /// Test initial state after deployment
    function test_initial_state() public {
        assertEq(address(airdropper.deployer()), address(deployHelper.deployer()));
        assertEq(airdropper.INITIAL_GOVERNOR(), initialGovernor.addr);
        assertEq(airdropper.getAccounts().length, 1); // Initial empty account
    }

    /// Test getter
    function test_getAccounts() public {
        bytes8[] memory keyIds = new bytes8[](3);
        keyIds[0] = bytes8(0x1234567890abcdef);
        keyIds[1] = bytes8(0xabcdef1234567890);
        keyIds[2] = bytes8(0xdeadbeefdeadbeef);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;

        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds, amounts);

        Airdropper.Account[] memory accounts = airdropper.getAccounts();
        assertEq(accounts.length, 4); // Initial empty account + 3 new accounts
        assertEq(accounts[1].keyId, keyIds[0]);
        assertEq(accounts[1].amount, amounts[0]);
        assertEq(accounts[2].keyId, keyIds[1]);
        assertEq(accounts[2].amount, amounts[1]);
        assertEq(accounts[3].keyId, keyIds[2]);
        assertEq(accounts[3].amount, amounts[2]);
    }

    /// Test prepareDrop single call
    function test_prepareDrop_single() public {
        bytes8[] memory keyIds = new bytes8[](1);
        keyIds[0] = bytes8(0x1234567890abcdef);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds, amounts);

        Airdropper.Account[] memory accounts = airdropper.getAccounts();
        assertEq(accounts.length, 2); // Initial empty account + 1 new account
        assertEq(accounts[1].keyId, keyIds[0]);
        assertEq(accounts[1].amount, amounts[0]);
    }

    /// Test prepareDrop reverts with overlapping keyIds
    function test_prepareDrop_reverts_overlapping() public {
        bytes8[] memory keyIds1 = new bytes8[](2);
        keyIds1[0] = bytes8(0x1234567890abcdef);
        keyIds1[1] = bytes8(0xabcdef1234567890);
        uint256[] memory amounts1 = new uint256[](2);
        amounts1[0] = 100;
        amounts1[1] = 200;

        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds1, amounts1);

        bytes8[] memory keyIds2 = new bytes8[](2);
        keyIds2[0] = bytes8(0x1234567890abcdef); // Overlapping keyId
        keyIds2[1] = bytes8(0xdeadbeefdeadbeef);
        uint256[] memory amounts2 = new uint256[](2);
        amounts2[0] = 150; // Different amount for overlapping keyId
        amounts2[1] = 300;

        (address deployedAddr,) = airdropper.deployer().predictAddress(keyIds2[0]);
        vm.startPrank(initialGovernor.addr);
        vm.expectRevert(abi.encodeWithSelector(Airdropper.AccountAlreadyExists.selector, deployedAddr));
        airdropper.prepareDrop(keyIds2, amounts2);

        vm.stopPrank();
    }

    /// Test prepareDrop multiple calls with different keyIds
    function test_prepareDrop_multiple() public {
        bytes8[] memory keyIds1 = new bytes8[](2);
        keyIds1[0] = bytes8(0x1234567890abcdef);
        keyIds1[1] = bytes8(0xabcdef1234567890);
        uint256[] memory amounts1 = new uint256[](2);
        amounts1[0] = 100;
        amounts1[1] = 200;

        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds1, amounts1);

        bytes8[] memory keyIds2 = new bytes8[](2);
        keyIds2[0] = bytes8(0xdeadbeefdeadbeef);
        keyIds2[1] = bytes8(0xfeedfacefeedface);
        uint256[] memory amounts2 = new uint256[](2);
        amounts2[0] = 300;
        amounts2[1] = 400;

        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds2, amounts2);

        Airdropper.Account[] memory accounts = airdropper.getAccounts();
        assertEq(accounts.length, 5); // Initial empty account + 4 new accounts
    }

    /// Test airdropByIndex reverts if the index is invalid
    function test_airdropByIndex_reverts_invalid_index() public {
        vm.startPrank(initialGovernor.addr);

        vm.expectRevert(Airdropper.InvalidIndex.selector);
        airdropper.airdropByIndex(0, 1); // No accounts yet, index 1 is invalid

        vm.stopPrank();
    }

    /// Test airdropByIndex airdrops to the correct account
    function test_airdropByIndex_airdrops_correct_account() public {
        bytes8[] memory keyIds = new bytes8[](2);
        keyIds[0] = bytes8(0x1234567890abcdef);
        keyIds[1] = bytes8(0xabcdef1234567890);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds, amounts);
        Airdropper.Account[] memory accounts = airdropper.getAccounts();
        assertEq(accounts.length, 3); // Initial empty account + 2 new accounts

        // Airdrop to index 1 (first account)
        (address expectedWallet,) = airdropper.deployer().predictAddress(keyIds[0]);
        vm.expectEmit(true, true, false, true);
        emit Airdropper.AirdropToKeyID(keyIds[0], payable(expectedWallet), amounts[0]);
        vm.deal(initialGovernor.addr, amounts[1]);
        vm.prank(initialGovernor.addr);
        airdropper.airdropByIndex{value: amounts[0]}(1, 1); // Index 1
        GPGRewardWallet wallet = GPGRewardWallet(payable(expectedWallet));
        assertEq(address(wallet).balance, amounts[0]);
        assertEq(wallet.keyId(), keyIds[0]);
        assertEq(wallet.admin(), initialGovernor.addr);

        // Airdrop to index 2 (second account)
        (expectedWallet,) = airdropper.deployer().predictAddress(keyIds[1]);
        vm.expectEmit(true, true, false, true);
        emit Airdropper.AirdropToKeyID(keyIds[1], payable(expectedWallet), amounts[1]);
        vm.deal(initialGovernor.addr, amounts[1]);
        vm.prank(initialGovernor.addr);
        airdropper.airdropByIndex{value: amounts[1]}(2, 2); // Index 2
        wallet = GPGRewardWallet(payable(expectedWallet));
        assertEq(address(wallet).balance, amounts[1]);
        assertEq(wallet.keyId(), keyIds[1]);
        assertEq(wallet.admin(), initialGovernor.addr);
    }

    /// Test airdropByIndex refunds excess
    function test_airdropByIndex_refunds_excess() public {
        bytes8[] memory keyIds = new bytes8[](1);
        keyIds[0] = bytes8(0x1234567890abcdef);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds, amounts);

        // Airdrop to index 1 with excess funds
        (address expectedWallet,) = airdropper.deployer().predictAddress(keyIds[0]);
        vm.expectEmit(true, true, false, true);
        emit Airdropper.AirdropToKeyID(keyIds[0], payable(expectedWallet), amounts[0]);
        vm.deal(initialGovernor.addr, 200); // Send more than needed
        vm.prank(initialGovernor.addr);
        airdropper.airdropByIndex{value: 200}(1, 1); // Index 1

        GPGRewardWallet wallet = GPGRewardWallet(payable(expectedWallet));
        assertEq(address(wallet).balance, amounts[0]);
        assertEq(wallet.keyId(), keyIds[0]);
        assertEq(wallet.admin(), initialGovernor.addr);

        // Check that excess was refunded
        assertEq(address(initialGovernor.addr).balance, 100); // Initial balance - 100 sent
    }

    /// Test reverts if called by non-governor
    function test_airdropByIndex_reverts_if_not_governor() public {
        vm.expectRevert(Airdropper.Unauthorized.selector);
        airdropper.airdropByIndex(1, 100); // Index 1
    }

    function test_prepareDrop_reverts_if_not_governor() public {
        vm.expectRevert(Airdropper.Unauthorized.selector);
        airdropper.prepareDrop(new bytes8[](0), new uint256[](0));
    }

    /// Test multiple airdrops across multiple ranges
    function test_airdropByIndex_multiple_ranges() public {
        bytes8[] memory keyIds = new bytes8[](13);
        keyIds[0] = bytes8(0x1234567890abcdef);
        keyIds[1] = bytes8(0xabcdef1234567890);
        keyIds[2] = bytes8(0xdeadbeefdeadbeef);
        keyIds[3] = bytes8(0xfeedfacefeedface);
        keyIds[4] = bytes8(0x1111111111111111);
        keyIds[5] = bytes8(0x2222222222222222);
        keyIds[6] = bytes8(0x3333333333333333);
        keyIds[7] = bytes8(0x4444444444444444);
        keyIds[8] = bytes8(0x5555555555555555);
        keyIds[9] = bytes8(0x6666666666666666);
        keyIds[10] = bytes8(0x7777777777777777);
        keyIds[11] = bytes8(0x8888888888888888);
        keyIds[12] = bytes8(0x9999999999999999);
        uint256[] memory amounts = new uint256[](13);
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < 13; i++) {
            amounts[i] = (i + 1) * 100; // Different amounts for each keyId
            totalAmount += amounts[i];
        }
        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds, amounts);
        Airdropper.Account[] memory accounts = airdropper.getAccounts();
        assertEq(accounts.length, 14); // Initial empty account + 13 new accounts
        for (uint256 i = 0; i < 13; i++) {
            assertEq(accounts[i + 1].keyId, keyIds[i]);
            assertEq(accounts[i + 1].amount, amounts[i]);
        }
        // Airdrop in multiple ranges
        vm.deal(initialGovernor.addr, totalAmount); // Send enough funds for all airdrops
        vm.prank(initialGovernor.addr);
        airdropper.airdropByIndex{value: 1500}(1, 5); // Airdrop first 5 accounts
        vm.prank(initialGovernor.addr);
        airdropper.airdropByIndex{value: 4000}(6, 10); // Airdrop next 5 accounts
        vm.prank(initialGovernor.addr);
        airdropper.airdropByIndex{value: 3600}(11, 13); // Airdrop last 3 accounts
        // Check balances
        address expectedWallet;
        for (uint256 i = 0; i < 13; i++) {
            (expectedWallet,) = airdropper.deployer().predictAddress(keyIds[i]);
            GPGRewardWallet wallet = GPGRewardWallet(payable(expectedWallet));
            assertEq(address(wallet).balance, amounts[i]);
            assertEq(wallet.keyId(), keyIds[i]);
            assertEq(wallet.admin(), initialGovernor.addr);
        }
    }

    /// Test clawback after deadline
    function test_clawback_after_deadline() public {
        bytes8[] memory keyIds = new bytes8[](2);
        keyIds[0] = bytes8(0x1234567890abcdef);
        keyIds[1] = bytes8(0xabcdef1234567890);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds, amounts);
        Airdropper.Account[] memory accounts = airdropper.getAccounts();
        assertEq(accounts.length, 3); // Initial empty account + 2 new accounts

        // Airdrop to both accounts
        address expectedWallet;
        (expectedWallet,) = airdropper.deployer().predictAddress(keyIds[0]);
        vm.expectEmit(true, true, false, true);
        emit Airdropper.AirdropToKeyID(keyIds[0], payable(expectedWallet), amounts[0]);
        vm.deal(initialGovernor.addr, amounts[0] + amounts[1]);
        vm.prank(initialGovernor.addr);
        airdropper.airdropByIndex{value: amounts[0] + amounts[1]}(1, 2);
        GPGRewardWallet wallet1 = GPGRewardWallet(payable(expectedWallet));
        assertEq(address(wallet1).balance, amounts[0]);
        (expectedWallet,) = airdropper.deployer().predictAddress(keyIds[1]);
        GPGRewardWallet wallet2 = GPGRewardWallet(payable(expectedWallet));
        assertEq(address(wallet2).balance, amounts[1]);

        // Skip past the deadline
        vm.warp(block.timestamp + 156 weeks + 1); // 3 years + 1 second
        vm.startPrank(initialGovernor.addr);

        (expectedWallet,) = airdropper.deployer().predictAddress(keyIds[0]);
        GPGRewardWallet wallet = GPGRewardWallet(payable(expectedWallet));
        wallet.recoverPostDeadmanSwitch(); // Recover funds after deadman switch
        assertEq(address(wallet).balance, 0); // All funds should be recovered

        (expectedWallet,) = airdropper.deployer().predictAddress(keyIds[1]);
        wallet = GPGRewardWallet(payable(expectedWallet));
        wallet.recoverPostDeadmanSwitch(); // Recover funds after deadman switch
        assertEq(address(wallet).balance, 0); // All funds should be recovered
        vm.stopPrank();

        // Check governor balance
        assertEq(address(initialGovernor.addr).balance, 300); // Total amount recovered
    }

    /// Test clawback reverts if called before deadman switch
    function test_clawback_reverts_before_deadman_switch() public {
        bytes8[] memory keyIds = new bytes8[](1);
        keyIds[0] = bytes8(0x1234567890abcdef);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        // Prepare
        vm.prank(initialGovernor.addr);
        airdropper.prepareDrop(keyIds, amounts);
        Airdropper.Account[] memory accounts = airdropper.getAccounts();
        assertEq(accounts.length, 2); // Initial empty account + 1 new account

        // Airdrop to the accounts
        (address expectedWallet,) = airdropper.deployer().predictAddress(keyIds[0]);
        vm.expectEmit(true, true, false, true);
        emit Airdropper.AirdropToKeyID(keyIds[0], payable(expectedWallet), amounts[0]);
        vm.deal(initialGovernor.addr, amounts[0]);
        vm.prank(initialGovernor.addr);
        airdropper.airdropByIndex{value: amounts[0]}(1, 1); // Index 1
        GPGRewardWallet wallet = GPGRewardWallet(payable(expectedWallet));
        assertEq(address(wallet).balance, amounts[0]);
        assertEq(wallet.keyId(), keyIds[0]);
        assertEq(wallet.admin(), initialGovernor.addr);

        // Try to clawback before deadman switch
        vm.warp(block.timestamp + 156 weeks); // 3 years + 1 second

        vm.startPrank(initialGovernor.addr);
        vm.expectRevert(GPGRewardWallet.DeadmanSwitchNotTriggered.selector);
        wallet.recoverPostDeadmanSwitch();
        vm.stopPrank();
        // Check governor balance remains unchanged
        assertEq(address(initialGovernor.addr).balance, 0);
    }
}
