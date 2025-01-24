// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Console.sol";
import { GPGWallet } from "src/GPGWalletImpl.sol";

contract GPGScript is Script {
    GPGWallet constant WALLET = GPGWallet(payable(address(1)));
    address EOA = makeAddr("eoa");
    bytes PUBKEY = hex"9833046768354e16092b06010401da470f0101074089ea06d9820134822b9ddaeef1929c50ddfd9bbcf7c0794f3082d864fecb30feb42f5a616368204f62726f6e7420287465612d676574682d7465737429203c7a6f62726f6e7440676d61696c2e636f6d3e88930413160a003b162104c4e971386f7e24899b765c6b49ceb217b43f237805026768354e021b03050b0908070202220206150a09080b020416020301021e07021780000a091049ceb217b43f2378e65600ff538b73b85fc29fe716c0857343ac1efb4ac2864fd346de79f00d0e0f6d6e8e970100cdaf800a4ea1c9fabe8c982a191bff567c16019dad016c06e643b689ff3fd60eb838046768354e120a2b060104019755010501010740cf010ab1e65c0a4560292d4f8faaf2c03b6e115f2482464404d12bed986c8f530301080788780418160a0020162104c4e971386f7e24899b765c6b49ceb217b43f237805026768354e021b0c000a091049ceb217b43f237866a900fe2d50d10d916ced462d925220880b538cc9ab4fde817aa5bb3928d4f2a46003a50100d420071637d56defa999a22bc43bf0b0b179cf288d9643a54e98c13eb346df0a";
    bytes SIGNATURE = hex"88750400160a001d162104c4e971386f7e24899b765c6b49ceb217b43f23780502678fee15000a091049ceb217b43f237896b40100f52ea02d10938943be614b37cdfb88e50747369bd0ee9fef045db0ff707ca90f00fe3e44932659240c78c30b880eb479a1e6dfada998d7e6f8868ef00eb4dc3dd000";

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes32 structHash = WALLET.getAddSignerStructHash(EOA, 0, 0, bytes32(0));
        WALLET.addSigner(EOA, 0, 0, bytes32(0), PUBKEY, SIGNATURE);

        console.log("Is EOA now signer?");
        console.log(WALLET.signers(EOA));

        vm.stopBroadcast();
    }
}
