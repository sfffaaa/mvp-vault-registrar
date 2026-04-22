// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultRegistrar.sol";
import "../src/PermissionedVault.sol";
import "../src/MockAsset.sol";

contract PermissionedVaultTest is Test {
    VaultRegistrar registrar;
    PermissionedVault vaultA; // HUMAN_KYC
    PermissionedVault vaultB; // AGENT_KYA
    MockAsset asset;

    address investor = address(0xBEEF);
    address agent    = address(0xCAFE);
    address stranger = address(0xDEAD);

    function setUp() public {
        asset = new MockAsset();
        registrar = new VaultRegistrar();

        vaultA = new PermissionedVault(
            address(asset), address(registrar),
            VaultRegistrar.IdentityType.HUMAN_KYC, "KYC Vault", "vKYC"
        );
        vaultB = new PermissionedVault(
            address(asset), address(registrar),
            VaultRegistrar.IdentityType.AGENT_KYA, "KYA Vault", "vKYA"
        );

        // fund and approve
        asset.mint(investor, 100e6);
        asset.mint(agent, 100e6);
        asset.mint(stranger, 100e6);

        vm.prank(investor); asset.approve(address(vaultA), type(uint256).max);
        vm.prank(agent);    asset.approve(address(vaultB), type(uint256).max);
        vm.prank(stranger); asset.approve(address(vaultA), type(uint256).max);
    }

    function test_registeredHumanCanDeposit() public {
        registrar.register(address(vaultA), investor, VaultRegistrar.IdentityType.HUMAN_KYC);
        vm.prank(investor);
        vaultA.deposit(5e6, investor);
        assertEq(asset.balanceOf(address(vaultA)), 5e6);
    }

    function test_registeredAgentCanDeposit() public {
        registrar.register(address(vaultB), agent, VaultRegistrar.IdentityType.AGENT_KYA);
        vm.prank(agent);
        vaultB.deposit(5e6, agent);
        assertEq(asset.balanceOf(address(vaultB)), 5e6);
    }

    function test_unregisteredMaxDepositIsZero() public view {
        assertEq(vaultA.maxDeposit(stranger), 0);
    }

    function test_unregisteredDepositReverts() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(PermissionedVault.NotPermitted.selector, stranger));
        vaultA.deposit(5e6, stranger);
    }

    function test_wrongTypeDepositReverts() public {
        // register agent in vaultA (which requires HUMAN_KYC) — wrong type
        registrar.register(address(vaultA), agent, VaultRegistrar.IdentityType.AGENT_KYA);
        vm.prank(agent);
        asset.approve(address(vaultA), type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(PermissionedVault.NotPermitted.selector, agent));
        vaultA.deposit(5e6, agent);
    }

    function test_revokedAgentDepositReverts() public {
        registrar.register(address(vaultB), agent, VaultRegistrar.IdentityType.AGENT_KYA);
        registrar.revoke(address(vaultB), agent);
        vm.prank(agent);
        vm.expectRevert(abi.encodeWithSelector(PermissionedVault.NotPermitted.selector, agent));
        vaultB.deposit(5e6, agent);
    }

    function test_revokedAgentMaxDepositIsZero() public {
        registrar.register(address(vaultB), agent, VaultRegistrar.IdentityType.AGENT_KYA);
        registrar.revoke(address(vaultB), agent);
        assertEq(vaultB.maxDeposit(agent), 0);
    }
}
