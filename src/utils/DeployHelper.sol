// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {Airdropper} from "src/Airdropper.sol";
import {GPGRewardWalletDeployer} from "src/GPGRewardWalletDeployer.sol";
import {GPGRewardWallet} from "src/GPGRewardWalletImpl.sol";

/*                                      _@@                                       
 _@                @_              _@@@@@                                       
 @@   @@@@@    _@@ #@\           @@@@@@@@@@      @@@--@@@         @@@@--@@@_    
/@% @@@   @@@@@@@   @@   @@       @@@@@@@     @@@@#    @@@@     @@@@@    @@@@@  
@@                  @@   @@       @@@@@@@    @@@@@     @@@@@    @@@@~    @@@@@@ 
@@                  @@            @@@@@@@   @@@@@@@@@@@@@@@@@           @@@@@@@ 
t@@                 @@   @@       @@@@@@@   @@@@@@                  @@@@#@@@@@@ 
 @@                @@@  @@@       @@@@@@@   @@@@@@@             @@@@@+   @@@@@@ 
 t@@              j@@   @@        @@@@@@@   #@@@@@@@          _@@@@@     @@@@@@ 
  \@@            @@@    @         @@@@@@@    @@@@@@@@_        @@@@@@@   _@@@@@@ 
    @%  @@@@@@@  @                 @@@@@@@@    @@@@@@@@@@@@   +@@@@@@@@@#@@@@@@ 
         t@@@/                      t@@@@+       t@@@@@@        @@@@@@+    t@@@@
*/

contract DeployHelper {
    error Unauthorized();
    error AlreadyDeployed();

    /// @notice The address of the initial governor to be set as owner for the Tea and MintManager contracts.
    address public immutable INITIAL_GOVERNOR;

    /// @notice The address of the GPGRewardWallet implementation.
    address public immutable IMPLEMENTATION;

    /// @notice The address of deployer contract for GPGRewardWallet.
    GPGRewardWalletDeployer public deployer;

    /// @notice The address of the Airdropper contract.
    Airdropper public airdropper;

    constructor(address initialGovernor_, bytes32 salt) {
        INITIAL_GOVERNOR = initialGovernor_;
        IMPLEMENTATION = address(new GPGRewardWallet{salt: salt}(initialGovernor_));
    }

    /// @notice Deploys the Tea and MintManager contracts.
    /// @param salt1 The salt to use for the GPGRewardWalletDeployer contract deployment.
    /// @param salt2 The salt to use for the Airdropper contract deployment.
    function deploy(bytes32 salt1, bytes32 salt2) external {
        // One time use.
        if (msg.sender != INITIAL_GOVERNOR) revert Unauthorized();
        if (address(deployer) != address(0)) revert AlreadyDeployed();

        deployer = new GPGRewardWalletDeployer{salt: salt1}(IMPLEMENTATION);
        airdropper = new Airdropper{salt: salt2}(deployer, INITIAL_GOVERNOR);

        assert(deployer.implementation() == IMPLEMENTATION);
        assert(address(airdropper.deployer()) == address(deployer));
    }
}
