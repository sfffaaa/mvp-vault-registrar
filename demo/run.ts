import { parseUnits, createPublicClient, http } from "viem"
import { privateKeyToAccount } from "viem/accounts"
import { makeRegistrarClient } from "../src/registrar.js"
import { makeVaultClient } from "../src/vault.js"
import { IdentityType } from "../src/types.js"
import { fujiChain } from "../src/chain.js"

const RPC_URL = "https://avalanche-fuji-c-chain-rpc.publicnode.com"
const CHAIN_ID = 43113

const publicClient = createPublicClient({ chain: fujiChain, transport: http(RPC_URL) })
async function waitTx(hash: `0x${string}`) {
  const receipt = await publicClient.waitForTransactionReceipt({ hash, timeout: 60_000 })
  if (receipt.status === "reverted") {
    throw new Error(`tx ${hash} reverted on-chain`)
  }
}

function requirePrivateKey(name: string): `0x${string}` {
  const val = process.env[name]
  // 32-byte private key = 64 hex chars + "0x" prefix = 66 chars total
  if (!val || !val.startsWith("0x") || val.length !== 66) {
    console.error(`Missing or invalid private key env var ${name} (expected 66-char 0x-prefixed hex)`)
    process.exit(1)
  }
  return val as `0x${string}`
}

function requireAddr(name: string): `0x${string}` {
  const val = process.env[name]
  if (!val || !val.startsWith("0x") || val.length !== 42) {
    console.error(`Missing or invalid address env var ${name}`)
    process.exit(1)
  }
  return val as `0x${string}`
}

function errorMessage(e: unknown): string {
  return e instanceof Error ? e.message : String(e)
}

function isAccessBlocked(msg: string): boolean {
  return msg.includes("NotPermitted") || msg.includes("ExceededMaxDeposit")
}

const DEPLOYER_PK  = requirePrivateKey("DEPLOYER_PK")
const ISSUER_PK    = requirePrivateKey("ISSUER_PK")
const INVESTOR_PK  = requirePrivateKey("INVESTOR_PK")
const AGENT_PK     = requirePrivateKey("AGENT_PK")
const STRANGER_PK  = requirePrivateKey("STRANGER_PK")

const REGISTRAR_ADDRESS = requireAddr("REGISTRAR_ADDRESS")
const VAULT_A_ADDRESS   = requireAddr("VAULT_A_ADDRESS")
const VAULT_B_ADDRESS   = requireAddr("VAULT_B_ADDRESS")
const ASSET_ADDRESS     = requireAddr("ASSET_ADDRESS")

const investorAddress = privateKeyToAccount(INVESTOR_PK).address
const agentAddress    = privateKeyToAccount(AGENT_PK).address
const strangerAddress = privateKeyToAccount(STRANGER_PK).address

async function run() {
  console.log("=== Vault Registrar Demo ===")
  console.log("Chain: Avalanche Fuji C-Chain")
  console.log("Registrar:          ", REGISTRAR_ADDRESS)
  console.log("VaultA (HUMAN_KYC): ", VAULT_A_ADDRESS)
  console.log("VaultB (AGENT_KYA): ", VAULT_B_ADDRESS)
  console.log("")

  const adminRegistrar = makeRegistrarClient(REGISTRAR_ADDRESS, DEPLOYER_PK, RPC_URL, CHAIN_ID)
  const investorVaultA = makeVaultClient(VAULT_A_ADDRESS, ASSET_ADDRESS, INVESTOR_PK, RPC_URL)
  const agentVaultB    = makeVaultClient(VAULT_B_ADDRESS, ASSET_ADDRESS, AGENT_PK, RPC_URL)
  const strangerVaultA = makeVaultClient(VAULT_A_ADDRESS, ASSET_ADDRESS, STRANGER_PK, RPC_URL)

  const FIVE_TOKENS = parseUnits("5", 6)

  // ─── Scenario 1: Human investor KYC via EIP-712 ───
  console.log("[1/4] Human investor KYC (EIP-712)...")
  try {
    const nonce = await adminRegistrar.nonce(VAULT_A_ADDRESS, investorAddress)
    const expiry = BigInt(Math.floor(Date.now() / 1000) + 3600)
    const sig = await adminRegistrar.signAuthorization(
      VAULT_A_ADDRESS, investorAddress, nonce, expiry, ISSUER_PK
    )
    const { hash: regHash } = await adminRegistrar.registerWithSig(
      VAULT_A_ADDRESS, investorAddress, expiry, sig
    )
    console.log("  registerWithSig → tx:", regHash)
    await waitTx(regHash)
    await waitTx((await investorVaultA.approveAsset()).hash)
    const { hash: depHash } = await investorVaultA.deposit(FIVE_TOKENS, investorAddress)
    await waitTx(depHash)
    console.log("  VaultA.deposit(5 tokens) → tx:", depHash)
    console.log("  ✓ Human investor deposited into VaultA")
  } catch (e) {
    console.log("  ✗", errorMessage(e))
  }
  console.log("")

  // ─── Scenario 2: AI agent KYA via direct register ───
  console.log("[2/4] AI agent KYA (direct register)...")
  try {
    const { hash: regHash } = await adminRegistrar.register(
      VAULT_B_ADDRESS, agentAddress, IdentityType.AGENT_KYA
    )
    console.log("  register(VaultB, agent, AGENT_KYA) → tx:", regHash)
    await waitTx(regHash)
    await waitTx((await agentVaultB.approveAsset()).hash)
    const { hash: depHash } = await agentVaultB.deposit(FIVE_TOKENS, agentAddress)
    await waitTx(depHash)
    console.log("  VaultB.deposit(5 tokens) → tx:", depHash)
    console.log("  ✓ AI agent deposited into VaultB")
  } catch (e) {
    console.log("  ✗", errorMessage(e))
  }
  console.log("")

  // ─── Scenario 3: Revoke agent → deposit fails ───
  console.log("[3/4] Revoke agent → re-attempt deposit...")
  try {
    const { hash: revokeHash } = await adminRegistrar.revoke(VAULT_B_ADDRESS, agentAddress)
    console.log("  revoke(VaultB, agent) → tx:", revokeHash)
    await waitTx(revokeHash)
    await agentVaultB.deposit(FIVE_TOKENS, agentAddress)
    console.log("  (unexpected: should have been rejected)")
  } catch (e) {
    const msg = errorMessage(e)
    if (isAccessBlocked(msg)) {
      console.log("  ✗ NotPermitted — agent revoked, deposit blocked")
    } else {
      console.log("  ✗", msg)
    }
  }
  console.log("")

  // ─── Scenario 4: Unregistered address ───
  console.log("[4/4] Unregistered address → attempt deposit...")
  try {
    const max = await strangerVaultA.maxDeposit(strangerAddress)
    console.log("  maxDeposit(stranger) =", max.toString(), "(0 = not permitted)")
    await strangerVaultA.approveAsset()
    await strangerVaultA.deposit(FIVE_TOKENS, strangerAddress)
    console.log("  (unexpected: should have been rejected)")
  } catch (e) {
    const msg = errorMessage(e)
    if (isAccessBlocked(msg)) {
      console.log("  ✗ NotPermitted — unregistered address blocked")
    } else {
      console.log("  ✗", msg)
    }
  }
  console.log("")
  console.log("Done.")
}

run().catch(console.error)
