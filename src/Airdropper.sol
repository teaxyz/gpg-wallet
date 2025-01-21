// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { GPGWalletDeployer } from "./GPGWalletDeployer.sol";

contract Airdropper {
    GPGWalletDeployer public deployer;

    constructor(GPGWalletDeployer _deployer) {
        deployer = _deployer;
    }

    function gpgAirdrop(bytes[] memory gpgKeys, uint[] memory amounts) public payable returns (address[] memory wallets) {
        require(gpgKeys.length == amounts.length, "Airdropper: keys and amounts length mismatch");

        wallets = new address[](gpgKeys.length);
        for (uint i = 0; i < gpgKeys.length; i++) {
            wallets[i] = deployer.deploy{value: amounts[i]}(gpgKeys[i]);
        }

        return wallets;
    }

    function eoaAirdrop(address[] memory addresses, uint[] memory amounts) public payable {
        require(addresses.length == amounts.length, "Airdropper: addresses and amounts length mismatch");

        address[] memory wallets = new address[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(amounts[i]);
            wallets[i] = addresses[i];
        }
    }
}
