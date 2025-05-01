// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @title GPGRewardWallet
/// @notice A smart contract wallet that supports GPG signatures for transaction execution
contract GPGRewardWallet is EIP712 {
    error DeadmanSwitchAlreadyTriggered();
    error DeadmanSwitchNotTriggered();

    /// @dev Address of the GPG signature verification precompile
    address public constant GPG_VERIFIER = address(0x696);

    /// @dev EIP712 typehash for withdrawing all funds
    bytes32 public constant WITHDRAW_ALL_TYPEHASH =
        keccak256("WithdrawAll(address to,uint256 paymasterFee,uint256 deadline,uint256 nonce)");

    /// @dev EIP712 typehash for executing a transaction
    bytes32 public constant EXECUTE_TYPEHASH =
        keccak256("Execute(address to,uint256 value,bytes data,uint256 paymasterFee,uint256 deadline,uint256 nonce)");

    /// @notice Address of the implementation contract
    /// @dev This is used in `publicKey()` to determine if calls are from a proxy
    address public immutable implementation;

    /// @notice Date after which the wallet will be considered inactive and recoverable by admin
    uint256 public immutable deadmanSwitchDate;

    /// @notice Address of the admin who can recover the wallet after the deadman switch date
    address payable public immutable admin;

    /// @notice Used to ensure uniqueness and ordering of executed messages
    uint256 public nextNonce;

    ////////////////////////////////////
    //          CONSTRUCTOR           //
    ////////////////////////////////////

    constructor(address _admin) EIP712("GPGRewardWallet", "1") {
        implementation = address(this);
        deadmanSwitchDate = block.timestamp + 3 years;
        admin = _admin;
    }

    ////////////////////////////////////
    //            EXTERNAL            //
    ////////////////////////////////////

    function recoverPostDeadmanSwitch() external returns (uint256 amount) {
        if (deadmanSwitchDate >= block.timestamp) {
            revert DeadmanSwitchNotTriggered();
        }

        uint256 amount = address(this).balance;
        (bool success,) = admin.call{value: amount}("");
        require(success, "GPGRewardWallet: execution failed");
    }

    /// @notice Withdraws all funds from the wallet to a specified address
    /// @param to Address to send the funds to
    /// @param paymasterFee Fee to be paid to the paymaster (if any)
    /// @param deadline Timestamp after which the signature is no longer valid (0 for no deadline)
    /// @param pubKey GPG public key of the signer
    /// @param signature GPG signature of the typed data
    function withdrawAll(
        address to,
        uint256 paymasterFee,
        uint256 deadline,
        bytes memory pubKey,
        bytes memory signature
    ) public {
        if (deadmanSwitchDate < block.timestamp) {
            // Tea cannot leave the wallet after deadmanSwitchDate
            revert DeadmanSwitchAlreadyTriggered();
        }

        require(deadline == 0 || deadline >= block.timestamp, "GPGRewardWallet: deadline expired");

        bytes32 digest = getWithdrawAllStructHash(to, paymasterFee, deadline, nextNonce++);
        require(_isValidGPGSignature(digest, pubKey, signature), "GPGRewardWallet: invalid signature");

        _executeCall(to, address(this).balance, "");

        if (paymasterFee > 0) _payPaymaster(paymasterFee);
    }

    /// @notice Executes a transaction with either a GPG signature
    /// @param to Destination address for the transaction
    /// @param value Amount of ETH to send
    /// @param data Calldata for the transaction
    /// @param paymasterFee Fee to be paid to the paymaster (if any)
    /// @param deadline Timestamp after which the signature is no longer valid (0 for no deadline)
    /// @param pubKey GPG public key of the signer
    /// @param signature The GPG signature
    /// @return returndata data Return data from the executed call
    function executeWithSig(
        address to,
        uint256 value,
        bytes memory data,
        uint256 paymasterFee,
        uint256 deadline,
        bytes memory pubKey,
        bytes memory signature
    ) public returns (bytes memory returndata) {
        require(deadline == 0 || deadline >= block.timestamp, "GPGRewardWallet: deadline expired");

        bytes32 digest = getExecuteStructHash(to, value, data, paymasterFee, deadline, nextNonce++);

        require(_isValidGPGSignature(digest, pubKey, signature), "GPGRewardWallet: invalid gpg signature");

        // Allows for token transfers and other calls after the deadmanSwitchDate
        if (deadmanSwitchDate < block.timestamp && (value > 0 || paymasterFee > 0)) {
            // Tea cannot leave the wallet after deadmanSwitchDate
            revert DeadmanSwitchAlreadyTriggered();
        }

        returndata = _executeCall(to, value, data);

        if (paymasterFee > 0) _payPaymaster(paymasterFee);
    }

    /// @notice Fallback function to receive ETH
    receive() external payable {}

    ////////////////////////////////////
    //            INTERNAL            //
    ////////////////////////////////////

    /// @param digest The message digest to verify
    /// @param signature The GPG signature to verify
    /// @return bool True if the signature is valid
    function _isValidGPGSignature(bytes32 digest, bytes memory pubKey, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes memory data = abi.encode(digest, keyId(), pubKey, signature);
        (bool success, bytes memory returndata) = GPG_VERIFIER.staticcall(data);
        require(success && returndata.length == 32, "GPGRewardWallet: gpg precompile error");

        return abi.decode(returndata, (bool));
    }

    /// @param amount Amount to pay the paymaster
    function _payPaymaster(uint256 amount) internal {
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "GPGRewardWallet: paymaster payment failed");
    }

    /// @param to Address to call
    /// @param value Amount of ETH to send
    /// @param data Calldata for the transaction
    /// @return returndata Data returned from the call
    function _executeCall(address to, uint256 value, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = to.call{value: value}(data);
        require(success, "GPGRewardWallet: execution failed");
        return returndata;
    }

    ////////////////////////////////////
    //              VIEW              //
    ////////////////////////////////////

    /// @notice Returns the GPG Key ID associated with this wallet
    /// @dev This is the last 8 bytes of the SHA hash of the public key
    /// @dev This value is hardcoded into the code of the proxy
    /// @dev This call will fail when performed on the implementation
    /// @return keyId The 8 byte Key ID associated with the wallet
    function keyId() public view returns (bytes8) {
        if (address(this) == implementation) {
            revert("GPGRewardWallet: implementation contract does not have a public key");
        }

        bytes8 keyIdFromCode;
        assembly {
            // Allocate memory for the bytes8
            let ptr := mload(0x40) // Get free memory pointer
            // Update the free memory pointer
            mstore(0x40, add(ptr, 0x20))
            // Copy the code to the pointer
            extcodecopy(address(), ptr, 0x2d, 0x20)
            // Load result into the bytes8 variable
            keyIdFromCode := mload(ptr)
        }
        return keyIdFromCode;
    }

    /// @notice Computes the struct hash for withdrawing all funds
    /// @param to Address to withdraw to
    /// @param paymasterFee Fee to be paid to the paymaster
    /// @param deadline Timestamp after which the signature is invalid
    /// @param nonce The wallet's nonce to ensure uniqueness and transaction ordering
    /// @return bytes32 The computed struct hash
    function getWithdrawAllStructHash(address to, uint256 paymasterFee, uint256 deadline, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(WITHDRAW_ALL_TYPEHASH, to, paymasterFee, deadline, nonce)));
    }

    /// @notice Computes the struct hash for executing a transaction
    /// @param to Destination address for the transaction
    /// @param value Amount of ETH to send
    /// @param data Calldata for the transaction
    /// @param paymasterFee Fee to be paid to the paymaster
    /// @param deadline Timestamp after which the signature is invalid
    /// @param nonce The wallet's nonce to ensure uniqueness and transaction ordering
    /// @return bytes32 The computed struct hash
    function getExecuteStructHash(
        address to,
        uint256 value,
        bytes memory data,
        uint256 paymasterFee,
        uint256 deadline,
        uint256 nonce
    ) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(EXECUTE_TYPEHASH, to, value, keccak256(data), paymasterFee, deadline, nonce))
        );
    }
}
