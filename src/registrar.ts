import {
  createPublicClient,
  createWalletClient,
  http,
  defineChain,
  type PublicClient,
  type WalletClient,
  type Address,
  type Hash,
} from "viem"
import { privateKeyToAccount } from "viem/accounts"
import { REGISTRAR_ABI, type IdentityTypeValue } from "./types.js"

const REGISTER_DOMAIN_TYPES = {
  Register: [
    { name: "vault", type: "address" },
    { name: "identity", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "expiry", type: "uint256" },
  ],
} as const

interface VaultRegistrarClientConfig {
  publicClient: PublicClient
  walletClient: WalletClient
  registrarAddress: Address
  chainId: number
}

export class VaultRegistrarClient {
  private publicClient: PublicClient
  private walletClient: WalletClient
  private registrarAddress: Address
  private chainId: number

  constructor(config: VaultRegistrarClientConfig) {
    this.publicClient = config.publicClient
    this.walletClient = config.walletClient
    this.registrarAddress = config.registrarAddress
    this.chainId = config.chainId
  }

  async signAuthorization(
    vault: Address,
    identity: Address,
    nonce: bigint,
    expiry: bigint,
    issuerPrivateKey: `0x${string}`
  ): Promise<`0x${string}`> {
    // signTypedData is a local cryptographic operation — no RPC transport needed.
    const account = privateKeyToAccount(issuerPrivateKey)
    return account.signTypedData({
      domain: {
        name: "VaultRegistrar",
        version: "1",
        chainId: this.chainId,
        verifyingContract: this.registrarAddress,
      },
      types: REGISTER_DOMAIN_TYPES,
      primaryType: "Register",
      message: { vault, identity, nonce, expiry },
    })
  }

  async registerWithSig(
    vault: Address,
    identity: Address,
    expiry: bigint,
    sig: `0x${string}`
  ): Promise<{ hash: Hash }> {
    const hash = await this.walletClient.writeContract({
      address: this.registrarAddress,
      abi: REGISTRAR_ABI,
      functionName: "registerWithSig",
      args: [vault, identity, expiry, sig],
      chain: null,
      account: this.walletClient.account!,
    })
    return { hash }
  }

  async register(
    vault: Address,
    identity: Address,
    type: IdentityTypeValue
  ): Promise<{ hash: Hash }> {
    const hash = await this.walletClient.writeContract({
      address: this.registrarAddress,
      abi: REGISTRAR_ABI,
      functionName: "register",
      args: [vault, identity, type],
      chain: null,
      account: this.walletClient.account!,
    })
    return { hash }
  }

  async revoke(vault: Address, identity: Address): Promise<{ hash: Hash }> {
    const hash = await this.walletClient.writeContract({
      address: this.registrarAddress,
      abi: REGISTRAR_ABI,
      functionName: "revoke",
      args: [vault, identity],
      chain: null,
      account: this.walletClient.account!,
    })
    return { hash }
  }

  async identityType(vault: Address, identity: Address): Promise<IdentityTypeValue> {
    return this.publicClient.readContract({
      address: this.registrarAddress,
      abi: REGISTRAR_ABI,
      functionName: "identityType",
      args: [vault, identity],
    }) as Promise<IdentityTypeValue>
  }

  async nonce(vault: Address, identity: Address): Promise<bigint> {
    return this.publicClient.readContract({
      address: this.registrarAddress,
      abi: REGISTRAR_ABI,
      functionName: "nonces",
      args: [vault, identity],
    }) as Promise<bigint>
  }
}

export function makeRegistrarClient(
  registrarAddress: Address,
  ownerPrivateKey: `0x${string}`,
  rpcUrl: string,
  chainId: number
): VaultRegistrarClient {
  const account = privateKeyToAccount(ownerPrivateKey)
  const transport = http(rpcUrl)
  const chain = defineChain({
    id: chainId,
    name: "Avalanche Fuji",
    nativeCurrency: { name: "Avalanche", symbol: "AVAX", decimals: 18 },
    rpcUrls: { default: { http: [rpcUrl] } },
    fees: { defaultPriorityFee: 1_000_000_000n },
  })
  const publicClient = createPublicClient({ chain, transport }) as PublicClient
  const walletClient = createWalletClient({ account, chain, transport }) as WalletClient
  return new VaultRegistrarClient({ publicClient, walletClient, registrarAddress, chainId })
}
