// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VaultRegistrar is Ownable, EIP712 {
    using ECDSA for bytes32;

    enum IdentityType { NONE, HUMAN_KYC, AGENT_KYA }

    bytes32 private constant REGISTER_TYPEHASH = keccak256(
        "Register(address vault,address identity,uint256 nonce,uint256 expiry)"
    );

    mapping(address vault => mapping(address identity => IdentityType)) public registry;
    mapping(address => bool) public authorizedIssuers;
    mapping(address vault => mapping(address identity => uint256)) public nonces;

    event Registered(address indexed vault, address indexed identity, IdentityType t);
    event Revoked(address indexed vault, address indexed identity);
    event IssuerSet(address indexed issuer, bool authorized);

    error InvalidIdentityType();
    error ExpiredSignature();
    error InvalidIssuer();

    constructor() Ownable(msg.sender) EIP712("VaultRegistrar", "1") {}

    function register(address vault, address identity, IdentityType t) external onlyOwner {
        if (t == IdentityType.NONE) revert InvalidIdentityType();
        registry[vault][identity] = t;
        emit Registered(vault, identity, t);
    }

    function registerWithSig(
        address vault,
        address identity,
        uint256 expiry,
        bytes calldata sig
    ) external {
        if (block.timestamp > expiry) revert ExpiredSignature();
        uint256 nonce = nonces[vault][identity]++;
        bytes32 structHash = keccak256(
            abi.encode(REGISTER_TYPEHASH, vault, identity, nonce, expiry)
        );
        address signer = _hashTypedDataV4(structHash).recover(sig);
        if (!authorizedIssuers[signer]) revert InvalidIssuer();
        registry[vault][identity] = IdentityType.HUMAN_KYC;
        emit Registered(vault, identity, IdentityType.HUMAN_KYC);
    }

    function revoke(address vault, address identity) external onlyOwner {
        registry[vault][identity] = IdentityType.NONE;
        emit Revoked(vault, identity);
    }

    function identityType(address vault, address identity) external view returns (IdentityType) {
        return registry[vault][identity];
    }

    function setIssuer(address issuer, bool authorized) external onlyOwner {
        authorizedIssuers[issuer] = authorized;
        emit IssuerSet(issuer, authorized);
    }
}
