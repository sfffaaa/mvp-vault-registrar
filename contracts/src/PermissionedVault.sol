// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./VaultRegistrar.sol";

contract PermissionedVault is ERC4626 {
    VaultRegistrar public immutable registrar;
    VaultRegistrar.IdentityType public immutable requiredType;

    error NotPermitted(address identity);

    modifier requirePermitted(address who) {
        if (registrar.identityType(address(this), who) != requiredType)
            revert NotPermitted(who);
        _;
    }

    constructor(
        address asset_,
        address registrar_,
        VaultRegistrar.IdentityType requiredType_,
        string memory name_,
        string memory symbol_
    ) ERC4626(IERC20(asset_)) ERC20(name_, symbol_) {
        registrar = VaultRegistrar(registrar_);
        requiredType = requiredType_;
    }

    function maxDeposit(address receiver) public view override returns (uint256) {
        if (registrar.identityType(address(this), receiver) != requiredType) return 0;
        return super.maxDeposit(receiver);
    }

    function maxMint(address receiver) public view override returns (uint256) {
        if (registrar.identityType(address(this), receiver) != requiredType) return 0;
        return super.maxMint(receiver);
    }

    // Write functions use requirePermitted modifier for a single identityType check.
    // deposit/mint call super which internally calls maxDeposit/maxMint — those also
    // check identityType. We accept the double-check to keep OZ's invariant intact.
    function deposit(uint256 assets, address receiver) public override requirePermitted(receiver) returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override requirePermitted(receiver) returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override requirePermitted(receiver) returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override requirePermitted(receiver) returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    function transfer(address to, uint256 amount) public override(ERC20, IERC20) requirePermitted(to) returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override(ERC20, IERC20) requirePermitted(to) returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}
