// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Storage } from "@optimism/libraries/Storage.sol";
import { Predeploys } from "@optimism/libraries/Predeploys.sol";

// todo: what if this is upgraded? before and after that tx will be different
// this means option 2

contract TeaWAPOracle {
    /// @notice The storage slot that contains data about the TWAP
    /// @dev bool(isActive) | uint8(nextIndex) | uint8(length) | uint64(fallbackPrice) | uint8(oracleDecimals) | address(oracle)
    bytes32 internal constant TWAP_METADATA_SLOT = bytes32(uint256(keccak256("opstack.twapmetadata")) - 1);

    /// @notice The storage slot that contains the start of the TWAP price array
    bytes32 internal constant TWAP_PRICES_SLOT = bytes32(uint256(keccak256("opstack.twapprices")) - 1);

    /// INTERNAL ///

    // todo: add events everywhere

    struct TWAPMetadata {
        bool isActive;
        uint8 nextIndex;
        uint8 twapLength;
        uint8 fallbackDecimals;
        uint56 fallbackPrice;
        uint8 oracleDecimals;
        address oracle;
    }

    function setOracleAddress(address _oracle) external  {
        // todo: is this the right admin?
        require(msg.sender == Predeploys.PROXY_ADMIN, "TeaWAPOracle: admin only");

        TWAPMetadata memory m = getTWAPMetadata();
        m.oracle = _oracle;
        _setTWAPMetadata(m);
    }

    /// @dev _price = Native Token per ETH (with _decimals of precision)
    ///      For example, if $TEA is worth 1/10th of ETH, we could represent
    ///      this as 10 with 0 decimals of precision. If 1 $TEA was worth
    ///      2 ETH, we would need to set _price = 5 and _decimals = 1.
    function setFallbackPrice(uint56 _price, uint8 _decimals) external {
        require(msg.sender == Predeploys.PROXY_ADMIN, "TeaWAPOracle: admin only");

        TWAPMetadata memory m = getTWAPMetadata();
        m.fallbackPrice = _price;
        m.fallbackDecimals = _decimals;
        _setTWAPMetadata(m);
    }

    function _updateTWAP() internal {
        TWAPMetadata memory m = getTWAPMetadata();

        (bool success, bytes memory returndata) = m.oracle.staticcall(
            abi.encodeWithSignature("getCurrentPrice()")
        );

        if (!success || returndata.length < 32) return;

        uint256 latestPrice = abi.decode(returndata, (uint256));

        if (latestPrice > 0) {
            uint256 priceSlot = uint256(TWAP_PRICES_SLOT) + m.nextIndex;
            Storage.setUint(bytes32(priceSlot), latestPrice);

            m.nextIndex = (m.nextIndex + 1) % m.twapLength;
            if (!m.isActive && m.nextIndex == 0) m.isActive = true;
            _setTWAPMetadata(m);
        }
    }

    function _getNativeTokenPerETH() internal view returns (uint256, uint8) {
        TWAPMetadata memory m = getTWAPMetadata();

        if (!m.isActive || m.twapLength == 0) return (m.fallbackPrice, 0);

        uint256 priceSlot;
        uint256 sum;
        for (uint i = 0; i < m.twapLength; i++) {
            priceSlot = uint256(TWAP_PRICES_SLOT) + i;
            sum += Storage.getUint(bytes32(priceSlot));
        }

        return (sum / m.twapLength, m.oracleDecimals);
    }

    function getTWAPMetadata() public view returns (TWAPMetadata memory) {
        uint256 data = Storage.getUint(TWAP_METADATA_SLOT);

        return TWAPMetadata({
            isActive: data >> 248 > 0,
            nextIndex: uint8(data >> 240),
            twapLength: uint8(data >> 232),
            fallbackDecimals: uint8(data >> 224),
            fallbackPrice: uint56(data >> 168),
            oracleDecimals: uint8(data >> 160),
            oracle: address(uint160(data))
        });
    }

    function _setTWAPMetadata(TWAPMetadata memory m) public {
        uint256 value = (
            uint256(m.isActive ? 1 : 0) << 248 |
            uint256(m.nextIndex) << 240 |
            uint256(m.twapLength) << 232 |
            uint256(m.fallbackDecimals) << 224 |
            uint256(m.fallbackPrice) << 168 |
            uint256(m.oracleDecimals) << 160 |
            uint256(uint160(m.oracle))
        );
        Storage.setUint(TWAP_METADATA_SLOT, value);
    }
}
