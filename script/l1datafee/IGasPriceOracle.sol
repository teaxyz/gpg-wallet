// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGasPriceOracle {
    function updateGasTokenPriceRatio() external;
    function convertETHToTea(uint256) external view returns (uint256);
    function teaPerETH() external view returns (uint160);
    function getLatestPrice() external view returns (uint96, uint160);
    function setFallbackPrice(uint160) external;
    function getFallbackPrice() external view returns (uint160);
    function getOracleConfig() external view returns (address,uint96,bool,address);
    function setOracleConfig(uint96,address) external;
    function CUSTOM_GAS_TOKEN_ORACLE_SLOT() external view returns (bytes32);
    function WETH_ADDRESS_SLOT() external view returns (bytes32);
    function CUSTOM_GAS_TOKEN_PRICE_SLOT() external view returns (bytes32);
    function FALLBACK_PRICE_SLOT() external view returns (bytes32);

    function __constructor__() external;
}
