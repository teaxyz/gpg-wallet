// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Console.sol";
import { Airdropper } from "src/Airdropper.sol";

// todo: add dotenv stuff
// forge script --chain sepolia script/NFT.s.sol:MyScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract AirdropScript is Script {
    Airdropper constant AIRDROPPER = Airdropper(address(1));


    // DO NOT CHANGE ORDER
    // Must stay consistent for proper JSON decoding
    struct AddressAirdrop {
        uint256 amount;
        address addr;
    }
    struct GPGAirdrop {
        uint256 amount;
        bytes keyId;
    }

    struct AddressAirdropBatch {
        AddressAirdrop[] airdrops;
        uint256 totalValue;
    }

    struct GPGAirdropBatch {
        GPGAirdrop[] airdrops;
        uint256 totalValue;
    }

    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(deployerPrivateKey);

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/data/keyids1.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        GPGAirdropBatch memory airdropBatch = abi.decode(data, (GPGAirdropBatch));

        uint sum;
        bytes8[] memory keyIds = new bytes8[](airdropBatch.airdrops.length);
        uint256[] memory amounts = new uint256[](airdropBatch.airdrops.length);
        for (uint i; i < airdropBatch.airdrops.length; i++) {
            sum += airdropBatch.airdrops[i].amount;
            keyIds[i] = bytes8(airdropBatch.airdrops[i].keyId);
            amounts[i] = airdropBatch.airdrops[i].amount;
            console.log(amounts[i]);
            console.logBytes8(keyIds[i]);
        }
        require(sum == airdropBatch.totalValue, "wrong total funds");

        // address[] memory wallets = AIRDROPPER.gpgAirdrop{value: sum}(keyIds, amounts);
        // do something with the wallets

        // vm.stopBroadcast();
    }
}
