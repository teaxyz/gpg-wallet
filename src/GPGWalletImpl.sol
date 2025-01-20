// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title GPGWallet
/// @notice A smart contract wallet that supports both GPG and ECDSA signatures for transaction execution
contract GPGWallet is EIP712 {
    /// @dev Address of the GPG signature verification precompile
    address constant GPG_VERIFIER = address(0xed);

    /// @notice Address of the implementation contract
    /// @dev This is used in `publicKey()` to determine if calls are from a proxy
    address public immutable implementation;

    /// @notice Mapping of authorized signing addresses for the wallet
    /// @dev This mapping consists of Ethereum addresses that can sign, in addition to the GPG public key
    mapping(address => bool) public signers;

    /// @notice Mapping to track used message digests
    mapping(bytes32 => bool) public usedDigests;

    ////////////////////////////////////
    //          CONSTRUCTOR           //
    ////////////////////////////////////

    constructor() EIP712("GPGWallet", "1") {
        implementation = address(this);
    }

    ////////////////////////////////////
    //            EXTERNAL            //
    ////////////////////////////////////

    /// @notice Adds a new signer to the wallet using a GPG signature
    /// @param signer Address of the new signer to add
    /// @param paymasterFee Fee to be paid to the paymaster (if any)
    /// @param deadline Timestamp after which the signature is no longer valid (0 for no deadline)
    /// @param salt Random value to ensure uniqueness of the message
    /// @param signature GPG signature of the typed data
    function addSigner(address signer, uint256 paymasterFee, uint256 deadline, bytes32 salt, bytes memory signature) public {
        require(deadline == 0 || deadline >= block.timestamp, "GPGWallet: deadline expired");

        bytes32 digest = _hashTypedDataV4(getAddSignerStructHash(signer, paymasterFee, deadline, salt));
        require(!usedDigests[digest], "GPGWallet: digest already used");
        usedDigests[digest] = true;

        require(_isValidGPGSignature(digest, signature), "GPGWallet: invalid signature");

        if (paymasterFee > 0) _payPaymaster(paymasterFee);

        signers[signer] = true;
    }

    /// @notice Withdraws all funds from the wallet to a specified address
    /// @param to Address to send the funds to
    /// @param paymasterFee Fee to be paid to the paymaster (if any)
    /// @param deadline Timestamp after which the signature is no longer valid (0 for no deadline)
    /// @param salt Random value to ensure uniqueness of the message
    /// @param signature GPG signature of the typed data
    function withdrawAll(address to, uint256 paymasterFee, uint256 deadline, bytes32 salt, bytes memory signature) public {
        require(deadline == 0 || deadline >= block.timestamp, "GPGWallet: deadline expired");

        bytes32 digest = _hashTypedDataV4(getWithdrawAllStructHash(to, paymasterFee, deadline, salt));
        require(!usedDigests[digest], "GPGWallet: digest already used");
        usedDigests[digest] = true;

        require(_isValidGPGSignature(digest, signature), "GPGWallet: invalid signature");

        if (paymasterFee > 0) _payPaymaster(paymasterFee);

        _executeCall(to, address(this).balance, "");
    }

    /// @notice Executes a transaction if called by an authorized signer
    /// @param to Destination address for the transaction
    /// @param value Amount of ETH to send
    /// @param data Calldata for the transaction
    /// @return data Return data from the executed call
    function executeBySigner(address to, uint256 value, bytes memory data) public returns (bytes memory) {
        require(signers[msg.sender], "GPGWallet: not a signer");
        return _executeCall(to, value, data);
    }

    /// @notice Executes a transaction with either a GPG or ECDSA signature
    /// @param to Destination address for the transaction
    /// @param value Amount of ETH to send
    /// @param data Calldata for the transaction
    /// @param paymasterFee Fee to be paid to the paymaster (if any)
    /// @param deadline Timestamp after which the signature is no longer valid (0 for no deadline)
    /// @param salt Random value to ensure uniqueness of the message
    /// @param signature The signature (either GPG or ECDSA)
    /// @param gpg Boolean indicating if the signature is GPG (true) or ECDSA (false)
    /// @return data Return data from the executed call
    function executeWithSig(address to, uint256 value, bytes memory data, uint256 paymasterFee, uint256 deadline, bytes32 salt, bytes memory signature, bool gpg) public returns (bytes memory) {
        require(deadline == 0 || deadline >= block.timestamp, "GPGWallet: deadline expired");

        bytes32 digest = _hashTypedDataV4(getExecuteStructHash(to, value, data, paymasterFee, deadline, salt));
        require(!usedDigests[digest], "GPGWallet: digest already used");
        usedDigests[digest] = true;

        if (gpg) {
            require(_isValidGPGSignature(digest, signature), "GPGWallet: invalid gpg signature");
        } else {
            require(signers[ECDSA.recover(digest, signature)], "GPGWallet: invalid ecdsa signature");
        }

        if (paymasterFee > 0) _payPaymaster(paymasterFee);

        return _executeCall(to, value, data);
    }

    /// @notice Fallback function to receive ETH
    receive() external payable {}

    ////////////////////////////////////
    //            INTERNAL            //
    ////////////////////////////////////

    /// @param digest The message digest to verify
    /// @param signature The GPG signature to verify
    /// @return bool True if the signature is valid
    function _isValidGPGSignature(bytes32 digest, bytes memory signature) internal view returns (bool) {
        bytes memory data = abi.encode(digest, publicKey(), signature);
        (bool success, bytes memory returndata) = GPG_VERIFIER.staticcall(data);
        require(success && returndata.length == 32, "GPGWallet: gpg precompile error");

        return abi.decode(returndata, (bool));
    }

    /// @param amount Amount to pay the paymaster
    function _payPaymaster(uint256 amount) internal {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "GPGWallet: paymaster payment failed");
    }

    /// @param to Address to call
    /// @param value Amount of ETH to send
    /// @param data Calldata for the transaction
    /// @return returndata Data returned from the call
    function _executeCall(address to, uint256 value, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = to.call{value: value}(data);
        require(success, "GPGWallet: execution failed");
        return returndata;
    }

    ////////////////////////////////////
    //              VIEW              //
    ////////////////////////////////////

    /// @notice Returns the GPG public key associated with this wallet
    /// @dev This value is hardcoded into the code of the proxy
    /// @dev This call will fail when performed on the implementation
    /// @return pubKey bytes The GPG public key
    function publicKey() public view returns (bytes memory pubKey) {
        if (address(this) == implementation) {
            revert("GPGWallet: implementation contract does not have a public key");
        } else {
            assembly {
                // Get the free memory pointer
                let ptr := mload(0x40)

                // 0x2d is the offset of the public key in the code
                extcodecopy(address(), ptr, 0x2d, 0x20)
                extcodecopy(address(), add(ptr, 0x20), add(0x2d, 0x20), mload(ptr))

                // Replace the free memory pointer
                mstore(0x40, add(add(ptr, 0x20), mload(ptr)))

                // Set result to point to our bytes array
                pubKey := ptr
            }
        }
    }

    /// @notice Computes the struct hash for adding a signer
    /// @param signer Address of the signer to add
    /// @param paymasterFee Fee to be paid to the paymaster
    /// @param deadline Timestamp after which the signature is invalid
    /// @param salt Random value to ensure uniqueness
    /// @return bytes32 The computed struct hash
    function getAddSignerStructHash(address signer, uint256 paymasterFee, uint256 deadline, bytes32 salt) public pure returns (bytes32) {
        bytes32 typehash = keccak256("AddSigner(address signer, uint256 paymasterFee, uint256 deadline, bytes32 salt)");
        return keccak256(abi.encode(typehash, signer, paymasterFee, deadline, salt));
    }

    /// @notice Computes the struct hash for withdrawing all funds
    /// @param to Address to withdraw to
    /// @param paymasterFee Fee to be paid to the paymaster
    /// @param deadline Timestamp after which the signature is invalid
    /// @param salt Random value to ensure uniqueness
    /// @return bytes32 The computed struct hash
    function getWithdrawAllStructHash(address to, uint256 paymasterFee, uint256 deadline, bytes32 salt) public pure returns (bytes32) {
        bytes32 typehash = keccak256("WithdrawAll(address to, uint256 paymasterFee, uint256 deadline, bytes32 salt)");
        return keccak256(abi.encode(typehash, to, paymasterFee, deadline, salt));
    }

    /// @notice Computes the struct hash for executing a transaction
    /// @param to Destination address for the transaction
    /// @param value Amount of ETH to send
    /// @param data Calldata for the transaction
    /// @param paymasterFee Fee to be paid to the paymaster
    /// @param deadline Timestamp after which the signature is invalid
    /// @param salt Random value to ensure uniqueness
    /// @return bytes32 The computed struct hash
    function getExecuteStructHash(address to, uint256 value, bytes memory data, uint256 paymasterFee, uint256 deadline, bytes32 salt) public pure returns (bytes32) {
        bytes32 typehash = keccak256("Execute(address to, uint256 value, bytes data, uint256 paymasterFee, uint256 deadline, bytes32 salt)");
        return keccak256(abi.encode(typehash, to, value, keccak256(data), paymasterFee, deadline, salt));
    }
}
