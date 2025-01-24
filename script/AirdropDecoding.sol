// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract AirdropJSONDecodingStructs {
    /**
     * !!! DO NOT CHANGE ORDER !!!
     *
     *     These structs MUST stay exactly as-is
     *     for JSON decoding to work as expected.
     *
     *     https://book.getfoundry.sh/cheatcodes/parse-json?highlight=json#decoding-json-objects-into-solidity-structs
     */
    struct AddressAirdrop {
        address addr;
        uint256 amount;
    }

    struct KeyIDAirdrop {
        uint256 amount;
        bytes keyId;
    }

    struct AddressAirdropBatch {
        AddressAirdrop[] airdrops;
        uint256 totalValue;
    }

    struct KeyIDAirdropBatch {
        KeyIDAirdrop[] airdrops;
        uint256 totalValue;
    }
}

contract AirdropDecoding is Script, AirdropJSONDecodingStructs {
    using Strings for uint256;

    function _getKeyIDAirdropBatch(uint256 num)
        internal
        view
        returns (bytes8[] memory keyIds, uint256[] memory amounts, uint256 sum)
    {
        bytes memory data = _readFile(true, num);
        KeyIDAirdropBatch memory airdropBatch = abi.decode(data, (KeyIDAirdropBatch));

        keyIds = new bytes8[](airdropBatch.airdrops.length);
        amounts = new uint256[](airdropBatch.airdrops.length);
        for (uint256 i; i < airdropBatch.airdrops.length; i++) {
            sum += airdropBatch.airdrops[i].amount;
            keyIds[i] = bytes8(airdropBatch.airdrops[i].keyId);
            amounts[i] = airdropBatch.airdrops[i].amount;
        }
        require(sum == airdropBatch.totalValue, "wrong total funds");
    }

    function _getAddressAirdropBatch(uint256 num)
        internal
        view
        returns (address[] memory addresses, uint256[] memory amounts, uint256 sum)
    {
        bytes memory data = _readFile(false, num);
        AddressAirdropBatch memory airdropBatch = abi.decode(data, (AddressAirdropBatch));

        addresses = new address[](airdropBatch.airdrops.length);
        amounts = new uint256[](airdropBatch.airdrops.length);
        for (uint256 i; i < airdropBatch.airdrops.length; i++) {
            sum += airdropBatch.airdrops[i].amount;
            addresses[i] = airdropBatch.airdrops[i].addr;
            amounts[i] = airdropBatch.airdrops[i].amount;
        }
        require(sum == airdropBatch.totalValue, "wrong total funds");
    }

    function _readFile(bool keyIdAirdrop, uint256 num) internal view returns (bytes memory data) {
        string memory root = vm.projectRoot();
        string memory filename;
        if (keyIdAirdrop) {
            filename = string.concat("keyids/", num.toString(), ".json");
        } else {
            filename = string.concat("addresses/", num.toString(), ".json");
        }
        string memory path = string.concat(root, "/script/data/", filename);
        string memory json = vm.readFile(path);
        data = vm.parseJson(json);
    }
}
