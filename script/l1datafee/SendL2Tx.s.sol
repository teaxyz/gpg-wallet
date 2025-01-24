// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

contract SendL2Tx is Script {
    address immutable EOA = makeAddr("eoa");

    function run() external {
        uint256 deployerPrivateKey = uint256(0x31dbb16ca3f7dadf52f55c0b8e8da910f742fb3891dd9f20d47baafa436a4d06);
        vm.startBroadcast(deployerPrivateKey);

        // 4 words * 32 bytes = 128 bytes
        bytes32 h = keccak256("hello");
        bytes memory cd = abi.encode(h, h, h, h);
        (bool s,) = EOA.call(cd);
        require(s);

        vm.stopBroadcast();
    }
}
