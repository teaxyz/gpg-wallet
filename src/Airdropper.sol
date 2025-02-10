// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {GPGWalletDeployer} from "./GPGWalletDeployer.sol";

contract Airdropper {
    GPGWalletDeployer public immutable deployer;

    event AirdropToKeyID(bytes8 keyId, address wallet, uint256 amount, bool newDeployment);
    event AirdropToAddress(address wallet, uint256 amount);

    constructor(GPGWalletDeployer _deployer) {
        deployer = _deployer;
    }

    function airdropToKeyIds(bytes8[] memory keyIds, uint256[] memory amounts)
        external
        payable
        returns (address[] memory wallets)
    {
        uint256 len = keyIds.length;
        require(len == amounts.length, "Airdropper: keys and amounts length mismatch");

        wallets = new address[](len);
        uint256 sum;
        for (uint256 i = 0; i < len; i++) {
            (address deployedAddr, bool isDeployed) = deployer.predictAddress(keyIds[i]);
            sum += amounts[i];
            if (!isDeployed) {
                wallets[i] = deployer.deploy{value: amounts[i]}(keyIds[i]);
                emit AirdropToKeyID(keyIds[i], wallets[i], amounts[i], true);
            } else {
                wallets[i] = deployedAddr;
                (bool success,) = deployedAddr.call{value: amounts[i]}("");
                require(success);
                emit AirdropToKeyID(keyIds[i], wallets[i], amounts[i], false);
            }
        }

        if (msg.value > sum) {
            (bool success,) = msg.sender.call{value: msg.value - sum}("");
            require(success);
        }

        return wallets;
    }

    function airdropToAddresses(address[] memory addrs, uint256[] memory amounts) external payable {
        uint256 len = addrs.length;
        require(len == amounts.length, "Airdropper: addresses and amounts length mismatch");

        for (uint256 i = 0; i < len; i++) {
            (bool success,) = addrs[i].call{value: amounts[i]}("");
            require(success);
            emit AirdropToAddress(addrs[i], amounts[i]);
        }
    }
}
