// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { GPGWalletDeployer } from "./GPGWalletDeployer.sol";

contract GPGAirdropper {
    GPGWalletDeployer public deployer;

    constructor(GPGWalletDeployer _deployer) {
        deployer = _deployer;
    }

    function airdrop(bytes[] memory gpgKeys, uint[] memory amounts) public payable returns (address[] memory wallets) {
        require(gpgKeys.length == amounts.length, "GPGAirdropper: keys and amounts length mismatch");

        wallets = new address[](gpgKeys.length);
        for (uint i = 0; i < gpgKeys.length; i++) {
            wallets[i] = deployer.deploy{value: amounts[i]}(gpgKeys[i]);
        }

        return wallets;
    }
}
