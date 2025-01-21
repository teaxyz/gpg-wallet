// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Based on ERC6551Registry: https://github.com/erc6551/reference/blob/main/src/ERC6551Registry.sol
contract GPGWalletDeployer {
    address public implementation;

    event GPGWalletDeployed(address walletAddress);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function deploy(bytes calldata /* gpgPublicKey */) external payable returns (address walletAddress) {
        assembly {
            // Memory Layout:
            // ----
            // 0x00   0xff                           (1 byte)
            // 0x01   registry (address)             (20 bytes)
            // 0x15   salt (bytes32)                 (32 bytes)
            // 0x35   Bytecode Hash (bytes32)        (32 bytes)
            // ----
            // 0x55   ERC-1167 Constructor + Header  (21 bytes)
            // 0x6A   implementation (address)       (20 bytes)
            // 0x7E   ERC-1167 Footer                (15 bytes)
            // 0x8D   key (bytes)                    (calldataload(24) bytes)

            let ptr := mload(0x40)
            let pubKeyLength := calldataload(0x24)

            if gt(pubKeyLength, 0xffa8) {
                mstore(0x00, 0x7e22dc72)
                revert(0x1c, 0x04)
            }

            let bytecodeLength := add(add(0x38, 0x20), pubKeyLength) // 0x8c + 0x20 (length) + pubKeyLength - 0x55

            mstore(add(ptr, 0x6d), 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(add(ptr, 0x5e), sload(implementation.slot)) // implementation
            mstore(add(ptr, 0x4a), 0x80600b3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header
            mstore(add(ptr, 0x39), bytecodeLength)
            mstore8(add(ptr, 0x55), 0x3d)
            mstore8(add(ptr, 0x56), 0x61)

            mstore(add(ptr, 0x8d), pubKeyLength)
            calldatacopy(add(add(ptr, 0x8d), 0x20), 0x44, pubKeyLength)

            // Copy create2 computation data to memory
            mstore8(ptr, 0xff) // 0xFF
            mstore(add(ptr, 0x35), keccak256(add(ptr, 0x55), bytecodeLength)) // keccak256(bytecode)
            mstore(add(ptr, 0x01), shl(96, address())) // deployer address

            // Compute account address & check for existing code
            walletAddress := shr(96, shl(96, keccak256(ptr, 0x55)))

            if iszero(extcodesize(walletAddress)) {
                let deployedAddress := create2(callvalue(), add(ptr, 0x55), bytecodeLength, 0)

                if iszero(eq(deployedAddress, walletAddress)) {
                    mstore(0x00, 0x7e22dc72)
                    revert(0x1c, 0x04)
                }
            }
        }

        emit GPGWalletDeployed(walletAddress);

        return walletAddress;
    }

    function predictAddress(bytes memory /* gpgPublicKey */) external view returns (address walletAddress, bool isDeployed) {
        assembly {
            let ptr := mload(0x40)
            let pubKeyLength := calldataload(0x24)
            let bytecodeLength := add(add(0x38, 0x20), pubKeyLength) // 0x8c + 0x20 (length) + pubKeyLength - 0x55

            if gt(bytecodeLength, 0xffff) {
                mstore(0x00, 0x7e22dc72)
                revert(0x1c, 0x04)
            }

            mstore(add(ptr, 0x6d), 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(add(ptr, 0x5e), sload(implementation.slot)) // implementation
            mstore(add(ptr, 0x4a), 0x80600b3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header
            mstore(add(ptr, 0x39), bytecodeLength)
            mstore8(add(ptr, 0x55), 0x3d)
            mstore8(add(ptr, 0x56), 0x61)

            mstore(add(ptr, 0x8d), pubKeyLength)
            calldatacopy(add(add(ptr, 0x8d), 0x20), 0x44, pubKeyLength)

            // Copy create2 computation data to memory
            mstore8(ptr, 0xff) // 0xFF
            mstore(add(ptr, 0x35), keccak256(add(ptr, 0x55), bytecodeLength)) // keccak256(bytecode)
            mstore(add(ptr, 0x01), shl(96, address())) // deployer address

            // Compute account address & check for existing code
            walletAddress := shr(96, shl(96, keccak256(ptr, 0x55)))
            isDeployed := iszero(iszero(extcodesize(walletAddress)))
        }
    }
}
