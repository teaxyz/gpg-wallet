// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { GPGWalletDeployer } from "src/GPGWalletDeployer.sol";
import { GPGWallet } from "src/GPGWalletImpl.sol";
import { Airdropper } from "src/Airdropper.sol";

contract GPGWalletTest is Test {
    GPGWalletDeployer deployer;
    GPGWallet impl;
    Airdropper airdropper;
    address eoa = makeAddr("eoa");
    bytes GPG_KEY = hex"9833046768354e16092b06010401da470f0101074089ea06d9820134822b9ddaeef1929c50ddfd9bbcf7c0794f3082d864fecb30feb42f5a616368204f62726f6e7420287465612d676574682d7465737429203c7a6f62726f6e7440676d61696c2e636f6d3e88930413160a003b162104c4e971386f7e24899b765c6b49ceb217b43f237805026768354e021b03050b0908070202220206150a09080b020416020301021e07021780000a091049ceb217b43f2378e65600ff538b73b85fc29fe716c0857343ac1efb4ac2864fd346de79f00d0e0f6d6e8e970100cdaf800a4ea1c9fabe8c982a191bff567c16019dad016c06e643b689ff3fd60eb838046768354e120a2b060104019755010501010740cf010ab1e65c0a4560292d4f8faaf2c03b6e115f2482464404d12bed986c8f530301080788780418160a0020162104c4e971386f7e24899b765c6b49ceb217b43f237805026768354e021b0c000a091049ceb217b43f237866a900fe2d50d10d916ced462d925220880b538cc9ab4fde817aa5bb3928d4f2a46003a50100d420071637d56defa999a22bc43bf0b0b179cf288d9643a54e98c13eb346df0a";

    function setUp() public {
        impl = new GPGWallet();
        deployer = new GPGWalletDeployer(address(impl));
        airdropper = new Airdropper(deployer);
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

    function testReceive() public {
        address walletAddr = deployer.deploy(new bytes(0));
        (bool success,) = walletAddr.call{value: 1}("");
        require(success);
    }

    // add signer with gpg key
    function testAddSigner() public {
        // gpg --export zobront@gmail.com | xxd -p | tr -d '\n'
        GPGWallet wallet = GPGWallet(payable(deployer.deploy(GPG_KEY)));

        // 0x675c245ebe33d8de244602f1a589229da9b31e300ffe3b6abcaa0d6ca351f975
        bytes32 structHash = wallet.getAddSignerStructHash(eoa, 0, 0, bytes32(0));

        // echo "{structHash}" | xxd -r -p | gpg --pinentry-mode loopback --detach-sign | xxd -p | tr -d '\n'
        bytes memory signed = hex"88750400160a001d162104c4e971386f7e24899b765c6b49ceb217b43f23780502678f2d6f000a091049ceb217b43f2378985a0100bbb317438d41cc64268716d2a0ed5390e2cf80f514b2f3ef4b67bca81951a04f010094b3e9534bbd1e1570f0d85247b35f7a5d15b5278b7335b1e55486472f09fe03";

        // this verifies on the precompile in tea-geth!
        console.logBytes(abi.encode(structHash, wallet.publicKey(), signed));
    }

    // withdraw all with gpg key

    // execute with gpg sig

    // execute with ecdsa

    // execute with eoa
}
