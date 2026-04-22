import { defineChain } from "viem"

export const fujiChain = defineChain({
  id: 43113,
  name: "Avalanche Fuji",
  nativeCurrency: { name: "Avalanche", symbol: "AVAX", decimals: 18 },
  rpcUrls: { default: { http: ["https://avalanche-fuji-c-chain-rpc.publicnode.com"] } },
  fees: { defaultPriorityFee: 1_000_000_000n },
})

export function makeChain(rpcUrl: string, chainId = 43113) {
  if (chainId === 43113 && rpcUrl === fujiChain.rpcUrls.default.http[0]) return fujiChain
  return defineChain({
    id: chainId,
    name: "Avalanche Fuji",
    nativeCurrency: { name: "Avalanche", symbol: "AVAX", decimals: 18 },
    rpcUrls: { default: { http: [rpcUrl] } },
    fees: { defaultPriorityFee: 1_000_000_000n },
  })
}
