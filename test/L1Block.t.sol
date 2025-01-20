// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console2 } from "forge-std/Test.sol";
import { L1Block } from "src/L1Block/L1BlockTEA.sol";
import { TeaWAPOracle } from "src/L1Block/TeaWAPOracle.sol";

contract L1BlockTest is Test {
    // L1Block l1Block;

    // function setUp() public {
    //     l1Block = new L1Block();
    // }

    // function testTWAPMetadata() public {
    //     TeaWAPOracle.TWAPMetadata memory m = TeaWAPOracle.TWAPMetadata({
    //         isActive: true,
    //         nextIndex: 8,
    //         twapLength: 10,
    //         fallbackDecimals: 0,
    //         fallbackPrice: 1_600_000,
    //         oracleDecimals: 18,
    //         oracle: address(this)
    //     });
    //     l1Block._setTWAPMetadata(m);

    //     TeaWAPOracle.TWAPMetadata memory result = l1Block.getTWAPMetadata();
    //     console2.log(result.isActive);
    //     console2.log(result.nextIndex);
    //     console2.log(result.twapLength);
    //     console2.log(result.fallbackDecimals);
    //     console2.log(result.fallbackPrice);
    //     console2.log(result.oracleDecimals);
    //     console2.log(result.oracle);

    // }
}
