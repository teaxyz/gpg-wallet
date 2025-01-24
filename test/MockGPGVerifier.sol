// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MockGPGVerifier {
    fallback(bytes calldata) external returns (bytes memory) {
        return abi.encode(true);
    }
}
