// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultRegistrar.sol";

contract VaultRegistrarOwnerTest is Test {
    VaultRegistrar registrar;
    address owner;
    address vault = address(0xAAA1);
    address agent = address(0xBBB1);
    address stranger = address(0xCCC1);

    function setUp() public {
        owner = address(this);
        registrar = new VaultRegistrar();
    }

    function test_register_agentKYA() public {
        registrar.register(vault, agent, VaultRegistrar.IdentityType.AGENT_KYA);
        assertEq(
            uint256(registrar.identityType(vault, agent)),
            uint256(VaultRegistrar.IdentityType.AGENT_KYA)
        );
    }

    function test_register_revertsForNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        registrar.register(vault, agent, VaultRegistrar.IdentityType.AGENT_KYA);
    }

    function test_register_revertsForNONE() public {
        vm.expectRevert(VaultRegistrar.InvalidIdentityType.selector);
        registrar.register(vault, agent, VaultRegistrar.IdentityType.NONE);
    }

    function test_revoke() public {
        registrar.register(vault, agent, VaultRegistrar.IdentityType.AGENT_KYA);
        registrar.revoke(vault, agent);
        assertEq(
            uint256(registrar.identityType(vault, agent)),
            uint256(VaultRegistrar.IdentityType.NONE)
        );
    }

    function test_revoke_revertsForNonOwner() public {
        registrar.register(vault, agent, VaultRegistrar.IdentityType.AGENT_KYA);
        vm.prank(stranger);
        vm.expectRevert();
        registrar.revoke(vault, agent);
    }

    function test_setIssuer() public {
        registrar.setIssuer(address(0xDDD1), true);
        assertTrue(registrar.authorizedIssuers(address(0xDDD1)));
        registrar.setIssuer(address(0xDDD1), false);
        assertFalse(registrar.authorizedIssuers(address(0xDDD1)));
    }

    function test_unregistered_returnsNone() public view {
        assertEq(
            uint256(registrar.identityType(vault, stranger)),
            uint256(VaultRegistrar.IdentityType.NONE)
        );
    }
}
