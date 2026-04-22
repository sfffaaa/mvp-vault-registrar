export const IdentityType = {
  NONE: 0,
  HUMAN_KYC: 1,
  AGENT_KYA: 2,
} as const

export type IdentityTypeValue = (typeof IdentityType)[keyof typeof IdentityType]

export const REGISTRAR_ABI = [
  {
    name: "register",
    type: "function",
    inputs: [
      { name: "vault", type: "address" },
      { name: "identity", type: "address" },
      { name: "t", type: "uint8" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    name: "registerWithSig",
    type: "function",
    inputs: [
      { name: "vault", type: "address" },
      { name: "identity", type: "address" },
      { name: "expiry", type: "uint256" },
      { name: "sig", type: "bytes" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    name: "revoke",
    type: "function",
    inputs: [
      { name: "vault", type: "address" },
      { name: "identity", type: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    name: "identityType",
    type: "function",
    inputs: [
      { name: "vault", type: "address" },
      { name: "identity", type: "address" },
    ],
    outputs: [{ name: "", type: "uint8" }],
    stateMutability: "view",
  },
  {
    name: "nonces",
    type: "function",
    inputs: [
      { name: "vault", type: "address" },
      { name: "identity", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
] as const

export const VAULT_ABI = [
  {
    name: "deposit",
    type: "function",
    inputs: [
      { name: "assets", type: "uint256" },
      { name: "receiver", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    name: "maxDeposit",
    type: "function",
    inputs: [{ name: "receiver", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    name: "totalAssets",
    type: "function",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
] as const

export const ASSET_ABI = [
  {
    name: "approve",
    type: "function",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
  },
] as const
