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

contract VaultRegistrarSigTest is Test {
    VaultRegistrar registrar;

    uint256 issuerKey = 0xA11CE;
    address issuer;
    address vault = address(0xAAA2);
    address investor = address(0xBBB2);

    bytes32 constant REGISTER_TYPEHASH = keccak256(
        "Register(address vault,address identity,uint256 nonce,uint256 expiry)"
    );

    function setUp() public {
        issuer = vm.addr(issuerKey);
        registrar = new VaultRegistrar();
        registrar.setIssuer(issuer, true);
    }

    function _sign(address _vault, address _identity, uint256 _nonce, uint256 _expiry)
        internal view returns (bytes memory)
    {
        bytes32 structHash = keccak256(
            abi.encode(REGISTER_TYPEHASH, _vault, _identity, _nonce, _expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", registrar.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function test_registerWithSig_happyPath() public {
        uint256 expiry = block.timestamp + 1 hours;
        bytes memory sig = _sign(vault, investor, 0, expiry);
        registrar.registerWithSig(vault, investor, expiry, sig);
        assertEq(
            uint256(registrar.identityType(vault, investor)),
            uint256(VaultRegistrar.IdentityType.HUMAN_KYC)
        );
    }

    function test_registerWithSig_incrementsNonce() public {
        uint256 expiry = block.timestamp + 1 hours;
        bytes memory sig = _sign(vault, investor, 0, expiry);
        registrar.registerWithSig(vault, investor, expiry, sig);
        assertEq(registrar.nonces(vault, investor), 1);
    }

    function test_registerWithSig_replayReverts() public {
        uint256 expiry = block.timestamp + 1 hours;
        bytes memory sig = _sign(vault, investor, 0, expiry);
        registrar.registerWithSig(vault, investor, expiry, sig);
        // replay same sig — nonce is now 1, sig was for nonce 0
        vm.expectRevert(VaultRegistrar.InvalidIssuer.selector);
        registrar.registerWithSig(vault, investor, expiry, sig);
    }

    function test_registerWithSig_expiredReverts() public {
        uint256 expiry = block.timestamp - 1;
        bytes memory sig = _sign(vault, investor, 0, expiry);
        vm.expectRevert(VaultRegistrar.ExpiredSignature.selector);
        registrar.registerWithSig(vault, investor, expiry, sig);
    }

    function test_registerWithSig_wrongIssuerReverts() public {
        uint256 expiry = block.timestamp + 1 hours;
        uint256 randomKey = 0xBAD;
        bytes32 structHash = keccak256(
            abi.encode(REGISTER_TYPEHASH, vault, investor, uint256(0), expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", registrar.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(randomKey, digest);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.expectRevert(VaultRegistrar.InvalidIssuer.selector);
        registrar.registerWithSig(vault, investor, expiry, sig);
    }
}
