import {
  type PublicClient,
  type WalletClient,
  type Address,
  type Hash,
  maxUint256,
  createPublicClient,
  createWalletClient,
  http,
} from "viem"
import { makeChain } from "./chain.js"
import { privateKeyToAccount } from "viem/accounts"
import { VAULT_ABI, ASSET_ABI } from "./types.js"

interface PermissionedVaultClientConfig {
  publicClient: PublicClient
  walletClient: WalletClient
  vaultAddress: Address
  assetAddress: Address
}

export class PermissionedVaultClient {
  private publicClient: PublicClient
  private walletClient: WalletClient
  private vaultAddress: Address
  private assetAddress: Address

  constructor(config: PermissionedVaultClientConfig) {
    this.publicClient = config.publicClient
    this.walletClient = config.walletClient
    this.vaultAddress = config.vaultAddress
    this.assetAddress = config.assetAddress
  }

  async approveAsset(): Promise<{ hash: Hash }> {
    const hash = await this.walletClient.writeContract({
      address: this.assetAddress,
      abi: ASSET_ABI,
      functionName: "approve",
      args: [this.vaultAddress, maxUint256],
      chain: null,
      account: this.walletClient.account!,
    })
    return { hash }
  }

  async deposit(assets: bigint, receiver: Address): Promise<{ hash: Hash }> {
    const hash = await this.walletClient.writeContract({
      address: this.vaultAddress,
      abi: VAULT_ABI,
      functionName: "deposit",
      args: [assets, receiver],
      chain: null,
      account: this.walletClient.account!,
    })
    return { hash }
  }

  async maxDeposit(receiver: Address): Promise<bigint> {
    return this.publicClient.readContract({
      address: this.vaultAddress,
      abi: VAULT_ABI,
      functionName: "maxDeposit",
      args: [receiver],
    }) as Promise<bigint>
  }

  async totalAssets(): Promise<bigint> {
    return this.publicClient.readContract({
      address: this.vaultAddress,
      abi: VAULT_ABI,
      functionName: "totalAssets",
      args: [],
    }) as Promise<bigint>
  }
}

export function makeVaultClient(
  vaultAddress: Address,
  assetAddress: Address,
  depositorPrivateKey: `0x${string}`,
  rpcUrl: string,
  chainId = 43113
): PermissionedVaultClient {
  const account = privateKeyToAccount(depositorPrivateKey)
  const transport = http(rpcUrl)
  const chain = makeChain(rpcUrl, chainId)
  const publicClient = createPublicClient({ chain, transport }) as PublicClient
  const walletClient = createWalletClient({ account, chain, transport }) as WalletClient
  return new PermissionedVaultClient({ publicClient, walletClient, vaultAddress, assetAddress })
}
