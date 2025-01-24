// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract FakeWETH {
    function name() public pure returns (string memory) {
        return "Wrapped Ether";
    }
}

contract MockOracle {
    address weth;

    constructor(address _weth) {
        weth = _weth;
    }

    function getReserves() public pure returns (uint256, uint256, uint256) {
        return (4_000_000e18, 2e18, 0);
    }

    function tokens() public view returns (address, address) {
        return (0x4200000000000000000000000000000000000006, weth);
    }

    function quote(address token, uint256 amount, uint256) external pure returns (uint256) {
        if (token == 0x4200000000000000000000000000000000000006) {
            return amount / 2_000_000;
        } else {
            return amount * 2_000_000;
        }
    }
}
