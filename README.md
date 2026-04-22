# Vault Registrar Interface for Permissioned ERC-20 Vaults

Reference implementation of a standardized on-chain Vault Registrar that gates ERC-4626 vault access by identity type. Demonstrates **KYC** (human investor via EIP-712) and **KYA** (Know Your Agent via direct registration) on Avalanche Fuji.

## What It Shows

- One `VaultRegistrar` serves multiple vaults — no per-vault allowlist logic
- **HUMAN_KYC**: issuer signs EIP-712 authorization off-chain, anyone submits it on-chain
- **AGENT_KYA**: admin directly registers an AI agent address (Know Your Agent)
- **Revoke**: removes access instantly — revoked agents/investors are blocked on next deposit
- ERC-4626 `maxDeposit()` returns 0 for unauthorized addresses (standard-compliant rejection)
- Replay protection: nonce per `(vault, identity)` pair in EIP-712 message

## Architecture

```
EIP-712 Signature (issuer)      Direct Call (admin/owner)
        |                              |
        v                              v
        +------- VaultRegistrar -------+
                 (vault, identity) → IdentityType
                 { NONE, HUMAN_KYC, AGENT_KYA }
                       |          |
                       v          v
              VaultA (HUMAN_KYC)  VaultB (AGENT_KYA)
              ERC-4626            ERC-4626
              deposit() checks    deposit() checks
              Registrar           Registrar
                       |
                       v
                  MockAsset (ERC-20 underlying)
```

## Contracts

| Contract | Description |
|---|---|
| `MockAsset.sol` | ERC-20 with public `mint()`, 6 decimals — underlying asset |
| `VaultRegistrar.sol` | Registry: `(vault, identity) → IdentityType`. EIP-712 for HUMAN_KYC, owner-only call for AGENT_KYA |
| `PermissionedVault.sol` | ERC-4626 vault that checks the Registrar on every deposit, withdrawal, mint, redeem, and token transfer |

## Policy Rules

| Rule | Value |
|---|---|
| HUMAN_KYC registration | EIP-712 signature from authorized issuer |
| AGENT_KYA registration | Owner direct call |
| Replay protection | Nonce per `(vault, identity)` pair |
| Revocation | Owner sets identity back to `NONE`; nonce is bumped to invalidate any outstanding signatures |

## Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Fuji testnet AVAX: https://faucet.avax.network/
- Node.js 18+

### Install

```bash
npm install
```

### Run Solidity Tests

```bash
cd contracts && forge test -v
```

### Run TypeScript Tests

```bash
npm test
```

### Deploy to Fuji

```bash
export DEPLOYER_PK=0x<your-private-key>
export ISSUER_ADDRESS=0x<issuer-address>
cd contracts
forge script script/Deploy.s.sol \
  --rpc-url https://avalanche-fuji-c-chain-rpc.publicnode.com \
  --broadcast --legacy
```

Copy the logged addresses to `.env` (see `.env.example`).

### Mint Test Tokens

```bash
export RPC=https://avalanche-fuji-c-chain-rpc.publicnode.com
cast send --rpc-url $RPC --private-key $DEPLOYER_PK $ASSET_ADDRESS \
  "mint(address,uint256)" <INVESTOR_ADDRESS> 100000000 --legacy
cast send --rpc-url $RPC --private-key $DEPLOYER_PK $ASSET_ADDRESS \
  "mint(address,uint256)" <AGENT_ADDRESS> 100000000 --legacy
cast send --rpc-url $RPC --private-key $DEPLOYER_PK $ASSET_ADDRESS \
  "mint(address,uint256)" <STRANGER_ADDRESS> 100000000 --legacy
```

### Run Demo

```bash
export $(cat .env | xargs)
npm run demo
```

Expected output:
```
=== Vault Registrar Demo ===
Chain: Avalanche Fuji C-Chain
...
[1/4] Human investor KYC (EIP-712)...
  registerWithSig → tx: 0x...
  VaultA.deposit(5 tokens) → tx: 0x...
  ✓ Human investor deposited into VaultA

[2/4] AI agent KYA (direct register)...
  register(VaultB, agent, AGENT_KYA) → tx: 0x...
  VaultB.deposit(5 tokens) → tx: 0x...
  ✓ AI agent deposited into VaultB

[3/4] Revoke agent → re-attempt deposit...
  revoke(VaultB, agent) → tx: 0x...
  ✗ NotPermitted — agent revoked, deposit blocked

[4/4] Unregistered address → attempt deposit...
  maxDeposit(stranger) = 0 (0 = not permitted)
  ✗ NotPermitted — unregistered address blocked

Done.
```

## Tech Stack

| Layer | Tool |
|---|---|
| Contracts | Solidity ^0.8.24, Foundry |
| OZ deps | `@openzeppelin/contracts` v5 (ERC4626, Ownable, EIP712) |
| TypeScript | ESM, NodeNext, viem v2, Jest |
| Chain | Avalanche Fuji C-Chain (chainId 43113) |
| RPC | `https://avalanche-fuji-c-chain-rpc.publicnode.com` |

## EIP-712 TypeHash

```
Register(address vault,address identity,uint256 nonce,uint256 expiry)
```

Domain: `name="VaultRegistrar"`, `version="1"`, `chainId=<deployment chain>`, `verifyingContract=<registrar address>`
