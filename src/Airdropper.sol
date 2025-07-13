// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {GPGRewardWalletDeployer} from "./GPGRewardWalletDeployer.sol";

contract Airdropper {
    struct Account {
        address rewardWallet;
        bytes8 keyId;
        uint256 amount;
    }

    error ArrayLengthMismatch();
    error AddressMismatch();
    error AccountAlreadyExists(address rewardWallet);
    error Unauthorized();
    error InvalidIndex();
    error TransferFailed();
    error NotDeployed(bytes8 keyId);

    event AirdropPrepared(address account, bytes8 keyId, uint256 amount);
    event AirdropToKeyID(bytes8 keyId, address wallet, uint256 amount);

    GPGRewardWalletDeployer public immutable deployer;
    address public immutable INITIAL_GOVERNOR;

    Account[] public accounts;
    mapping(address => uint256) public accountIdx;

    modifier onlyGovernor() {
        if (msg.sender != INITIAL_GOVERNOR) revert Unauthorized();
        _;
    }

    constructor(GPGRewardWalletDeployer _deployer, address initialGovernor) {
        deployer = _deployer;
        INITIAL_GOVERNOR = initialGovernor;

        accounts.push(Account(address(0), bytes8(0), 0)); // Empty for index 0
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Getters                                  */
    /* -------------------------------------------------------------------------- */

    function getAccounts() external view returns (Account[] memory) {
        return accounts;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Governor                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Configures airdrop to GPG Reward Accounts. Duplicate addresses not permitted.
     * @param keyIds The array of key IDs.
     * @param amounts The array of amounts.
     */
    function prepareDrop(bytes8[] memory keyIds, uint256[] memory amounts) external onlyGovernor {
        uint256 len = keyIds.length;

        if (len != amounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < len; i++) {
            (address deployedAddr, bool isDeployed) = deployer.predictAddress(keyIds[i]);

            // Deploy if needed.
            if (!isDeployed) {
                address confirmDeployedAddr = deployer.deploy(keyIds[i]);
                if (confirmDeployedAddr != deployedAddr) {
                    revert AddressMismatch();
                }
            }

            _addAccount({rewardWallet: deployedAddr, keyId: keyIds[i], amount: amounts[i]});
        }
    }

    /**
     * @notice Airdrops funds to accounts by index range. Drops to range [start, stop] inclusive.
     * @param start The starting index (1-based).
     * @param stop The ending index (1-based).
     */
    function airdropByIndex(uint256 start, uint256 stop) external payable onlyGovernor {
        if (start == 0) revert InvalidIndex();
        if (stop < start) revert InvalidIndex();

        uint256 sum;

        for (uint256 i = start; i <= stop; i++) {
            if (i >= accounts.length) revert InvalidIndex();

            // References
            Account storage account = accounts[i];
            uint256 amount = account.amount;
            if (amount == 0) continue; // Skip if no amount to airdrop

            // Confirm config
            (address deployedAddr, bool isDeployed) = deployer.predictAddress(account.keyId);
            if (!isDeployed) revert NotDeployed(account.keyId);
            if (deployedAddr != account.rewardWallet) revert AddressMismatch();

            // Accumulator
            sum += amount;

            // Effects
            account.amount = 0;

            // Interaction
            (bool success,) = account.rewardWallet.call{value: amount}("");
            if (!success) revert TransferFailed();

            emit AirdropToKeyID({keyId: account.keyId, wallet: account.rewardWallet, amount: amount});
        }

        if (msg.value > sum) {
            (bool success,) = msg.sender.call{value: msg.value - sum}("");
            if (!success) revert TransferFailed();
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Internal                                  */
    /* -------------------------------------------------------------------------- */

    function _addAccount(address rewardWallet, bytes8 keyId, uint256 amount) internal {
        if (accountIdx[rewardWallet] != 0) {
            revert AccountAlreadyExists(rewardWallet);
        }

        accountIdx[rewardWallet] = accounts.length;
        accounts.push(Account({rewardWallet: rewardWallet, keyId: keyId, amount: amount}));

        emit AirdropPrepared(rewardWallet, keyId, amount);
    }
}
