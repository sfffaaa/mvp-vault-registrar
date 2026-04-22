// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockAsset.sol";
import "../src/VaultRegistrar.sol";
import "../src/PermissionedVault.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_PK");
        address issuer = vm.envAddress("ISSUER_ADDRESS");

        vm.startBroadcast(deployerKey);

        MockAsset asset = new MockAsset();
        VaultRegistrar registrar = new VaultRegistrar();

        PermissionedVault vaultA = new PermissionedVault(
            address(asset),
            address(registrar),
            VaultRegistrar.IdentityType.HUMAN_KYC,
            "KYC Vault",
            "vKYC"
        );

        PermissionedVault vaultB = new PermissionedVault(
            address(asset),
            address(registrar),
            VaultRegistrar.IdentityType.AGENT_KYA,
            "KYA Vault",
            "vKYA"
        );

        registrar.setIssuer(issuer, true);

        vm.stopBroadcast();

        console.log("MockAsset:         ", address(asset));
        console.log("VaultRegistrar:    ", address(registrar));
        console.log("VaultA (HUMAN_KYC):", address(vaultA));
        console.log("VaultB (AGENT_KYA):", address(vaultB));
    }
}
