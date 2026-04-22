import { describe, it, expect } from "@jest/globals"
import { VaultRegistrarClient } from "../src/registrar.js"
import { privateKeyToAccount } from "viem/accounts"

describe("VaultRegistrarClient.signAuthorization", () => {
  const issuerKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" as const
  const registrarAddress = "0x1234567890123456789012345678901234567890" as const
  const vault = "0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa" as const
  const identity = "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB" as const

  const client = new VaultRegistrarClient({
    publicClient: null as any,
    walletClient: null as any,
    registrarAddress,
    chainId: 43113,
  })

  it("returns a 65-byte hex signature", async () => {
    const expiry = BigInt(Math.floor(Date.now() / 1000) + 3600)
    const nonce = 0n
    const sig = await client.signAuthorization(vault, identity, nonce, expiry, issuerKey)
    expect(sig).toMatch(/^0x[0-9a-f]{130}$/i)
  })

  it("produces different sigs for different nonces", async () => {
    const expiry = BigInt(Math.floor(Date.now() / 1000) + 3600)
    const sig0 = await client.signAuthorization(vault, identity, 0n, expiry, issuerKey)
    const sig1 = await client.signAuthorization(vault, identity, 1n, expiry, issuerKey)
    expect(sig0).not.toEqual(sig1)
  })
})
