// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MockAsset.sol";

contract MockAssetTest is Test {
    MockAsset asset;

    function setUp() public {
        asset = new MockAsset();
    }

    function test_nameAndSymbol() public view {
        assertEq(asset.name(), "Mock Asset");
        assertEq(asset.symbol(), "mASSET");
        assertEq(asset.decimals(), 6);
    }

    function test_mint() public {
        asset.mint(address(0xBEEF), 100e6);
        assertEq(asset.balanceOf(address(0xBEEF)), 100e6);
    }
}
