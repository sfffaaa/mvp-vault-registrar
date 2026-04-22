// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./VaultRegistrar.sol";

contract PermissionedVault is ERC4626 {
    VaultRegistrar public immutable registrar;
    VaultRegistrar.IdentityType public immutable requiredType;

    error NotPermitted(address identity);

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

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        if (registrar.identityType(address(this), receiver) != requiredType)
            revert NotPermitted(receiver);
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override returns (uint256) {
        if (registrar.identityType(address(this), receiver) != requiredType)
            revert NotPermitted(receiver);
        return super.mint(shares, receiver);
    }

    // withdraw() and redeem() are intentionally NOT gated.
    // This MVP gates entry (deposit/mint) only. Withdrawal receivers are not
    // restricted because share ownership is already an implicit entry credential.
    // A production vault enforcing strict receiver gating should also override
    // withdraw()/redeem() and check receiver identity.
}
