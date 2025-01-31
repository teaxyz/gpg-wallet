// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console2 } from "forge-std/Test.sol";
import { AirdropDecoding } from "script/AirdropDecoding.sol";

contract AirdropDecoderTest is Test, AirdropDecoding {
    AirdropDecoding airdropDecoding;

    function testGetKeyIDAirdropBatch() public {
        (bytes8[] memory keyIds, uint256[] memory amounts, uint256 sum) = _getKeyIDAirdropBatch(0);
        assertEq(keyIds[0], bytes8(0x1111111111111111));
        assertEq(keyIds[1], bytes8(0x49ceb217b43f2378));

        assertEq(amounts[0], 1);
        assertEq(amounts[1], 1);

        assertEq(sum, 2);
    }
}
