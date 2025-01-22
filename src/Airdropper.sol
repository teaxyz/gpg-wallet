// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { GPGWalletDeployer } from "./GPGWalletDeployer.sol";

contract Airdropper {
    GPGWalletDeployer public deployer;

    constructor(GPGWalletDeployer _deployer) {
        deployer = _deployer;
    }

    function gpgAirdrop(bytes8[] memory keyIds, uint[] memory amounts) public payable returns (address[] memory wallets) {
        require(keyIds.length == amounts.length, "Airdropper: keys and amounts length mismatch");

        wallets = new address[](keyIds.length);
        for (uint i = 0; i < keyIds.length; i++) {
            (, bool isDeployed) = deployer.predictAddress(keyIds[i]);
            require(!isDeployed, "key already deployed");
            wallets[i] = deployer.deploy{value: amounts[i]}(keyIds[i]);
        }

        return wallets;
    }

    function gpgAirdropToExisting(bytes8[] memory keyIds, uint[] memory amounts) public payable returns (address[] memory wallets) {
        require(keyIds.length == amounts.length, "Airdropper: keys and amounts length mismatch");

        wallets = new address[](keyIds.length);
        for (uint i = 0; i < keyIds.length; i++) {
            bool isDeployed;
            (wallets[i], isDeployed) = deployer.predictAddress(keyIds[i]);

            require(isDeployed, "key already deployed");
            payable(wallets[i]).transfer(amounts[i]);
        }

        return wallets;
    }

    function eoaAirdrop(address[] memory addresses, uint[] memory amounts) public payable {
        require(addresses.length == amounts.length, "Airdropper: addresses and amounts length mismatch");

        for (uint i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(amounts[i]);
        }
    }
}
