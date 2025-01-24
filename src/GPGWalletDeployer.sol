// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Based on ERC6551Registry: https://github.com/erc6551/reference/blob/main/src/ERC6551Registry.sol
contract GPGWalletDeployer {
    address public implementation;

    // cast keccak "GPGWalletDeployed(address,uint256)
    bytes32 constant WALLET_DEPLOYED_EVENT = 0xf934bdb517e8b19d76877e2539a250338b642109c704f9b5a12af67cc82c8e24;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function deploy(bytes8 /* keyId */ ) external payable returns (address walletAddress) {
        assembly {
            // Memory Layout:
            // ----
            // 0x00   0xff                           (1 byte)
            // 0x01   registry (address)             (20 bytes)
            // 0x15   salt (bytes32)                 (32 bytes)
            // 0x35   Bytecode Hash (bytes32)        (32 bytes)
            // ----
            // 0x55   ERC-1167 Constructor + Header  (20 bytes)
            // 0x69   implementation (address)       (20 bytes)
            // 0x7D   ERC-1167 Footer                (15 bytes)
            // 0x8D   keyID (bytes8)                 (8 bytes)

            let ptr := mload(0x40)
            let bytecodeLength := 0x40 // 0x8D + 0x08 - 0x55

            mstore(add(ptr, 0x6c), 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(add(ptr, 0x5d), sload(implementation.slot)) // implementation
            mstore(add(ptr, 0x49), 0x3d603f80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header
            calldatacopy(add(ptr, 0x8d), 0x04, 0x20)

            // Copy create2 computation data to memory
            mstore8(ptr, 0xff) // 0xFF
            mstore(add(ptr, 0x35), keccak256(add(ptr, 0x55), bytecodeLength)) // keccak256(bytecode)
            mstore(add(ptr, 0x01), shl(96, address())) // deployer address

            // Compute account address & check for existing code
            walletAddress := shr(96, shl(96, keccak256(ptr, 0x55)))

            if iszero(iszero(extcodesize(walletAddress))) {
                mstore(0x00, 0x340630c7) // `WalletAlreadyDeployed()`.
                revert(0x1c, 0x04)
            }

            let deployedAddress := create2(callvalue(), add(ptr, 0x55), bytecodeLength, 0)

            if iszero(eq(deployedAddress, walletAddress)) {
                mstore(0x89, 0x705f331c1) // `AccountCreationFailed(bytes8)`
                revert(0x89, 0xc) // keyId is already at 0x8D
            }

            mstore(add(ptr, 0x95), walletAddress)
            mstore(add(ptr, 0xb5), callvalue())
            log1(add(ptr, 0x95), 0x40, WALLET_DEPLOYED_EVENT) // `GPGWalletDeployed(address,uint256)`
        }

        return walletAddress;
    }

    function predictAddress(bytes8 /* gpgPublicKey */ )
        external
        view
        returns (address walletAddress, bool isDeployed)
    {
        assembly {
            let ptr := mload(0x40)
            let bytecodeLength := 0x40 // 0x8D + 0x08 - 0x55

            mstore(add(ptr, 0x6c), 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(add(ptr, 0x5d), sload(implementation.slot)) // implementation
            mstore(add(ptr, 0x49), 0x3d603f80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header
            calldatacopy(add(ptr, 0x8d), 0x04, 0x20)

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
