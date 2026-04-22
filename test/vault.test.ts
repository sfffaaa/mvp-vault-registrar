import { describe, it, expect } from "@jest/globals"
import { PermissionedVaultClient } from "../src/vault.js"

describe("PermissionedVaultClient", () => {
  it("exports PermissionedVaultClient class", () => {
    expect(PermissionedVaultClient).toBeDefined()
  })

  it("can be instantiated with config", () => {
    const client = new PermissionedVaultClient({
      publicClient: null as any,
      walletClient: null as any,
      vaultAddress: "0x1234567890123456789012345678901234567890",
      assetAddress: "0x1234567890123456789012345678901234567891",
    })
    expect(client).toBeDefined()
  })
})
