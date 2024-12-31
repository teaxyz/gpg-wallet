// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Based on ERC6551Registry: https://github.com/erc6551/reference/blob/main/src/ERC6551Registry.sol
contract GPGWalletDeployer {
    address public implementation;

    event GPGWalletDeployed(address walletAddress);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    // This has to remain external, because calldataload doesn't work properly internally.
    function deploy(bytes calldata gpgPublicKey) external payable returns (address walletAddress) {
        assembly {
            let ptr := mload(0x40)
            let pubKeyLength := calldataload(0x24)
            let bytecodeLength := add(add(0x37, 0x20), pubKeyLength) // 0x8c + 0x20 (length) + pubKeyLength - 0x55

            mstore(add(ptr, 0x6c), 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(add(ptr, 0x5d), sload(implementation.slot)) // implementation
            mstore(add(ptr, 0x49), 0x80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header
            mstore8(add(ptr, 0x55), 0x3d)
            mstore8(add(ptr, 0x56), 0x60)
            mstore8(add(ptr, 0x57), bytecodeLength)

            mstore(add(ptr, 0x8c), pubKeyLength)
            calldatacopy(add(add(ptr, 0x8c), 0x20), 0x44, pubKeyLength)

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

            mstore(0x40, add(add(ptr, 0x55), bytecodeLength))
        }

        emit GPGWalletDeployed(walletAddress);

        return walletAddress;
    }

    function predictAddress(bytes memory gpgPublicKey) external view returns (address walletAddress, bool isDeployed) {
        assembly {
            let ptr := mload(0x40)

            mstore(add(ptr, 0x6c), 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(add(ptr, 0x5d), sload(implementation.slot)) // implementation
            mstore(add(ptr, 0x49), 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            let pubKeyLength := calldataload(0x24)
            mstore(add(ptr, 0x8c), pubKeyLength)
            calldatacopy(add(add(ptr, 0x8c), 0x20), 0x44, pubKeyLength)
            let bytecodeLength := add(add(0x37, 0x20), pubKeyLength) // 0x8c + 0x20 (length) + pubKeyLength - 0x55

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
