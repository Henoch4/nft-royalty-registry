# Royalty Registry — Enforced NFT Royalties

> The Royalty Registry records a canonical royalty policy per token collection and gives marketplaces a single source of truth to query at sale time - no more inconsistent secondary-market cuts.

## What it does

The Royalty Registry records a canonical royalty policy per token collection and gives marketplaces a single source of truth to query at sale time - no more inconsistent secondary-market cuts. The entire lifecycle lives in one contract, every button in the UI calls a real function on it — there is no mock backend.

## Contract

| | |
|---|---|
| File | `contracts/NFTRoyaltyRegistry.sol` |
| Contract name | `NFTRoyaltyRegistry` (inherits `ReentrancyGuard, Ownable`) |
| Solidity | `^0.8.20` |
| State functions | 5 (of which 1 payable) |
| Deployed (mainnet 677) | not yet deployed — placeholder `0x000…000` |

### Function surface

| Function | Type | Returns |
|---|---|---|
| `owner` | view | address |
| `registerRoyalty` | write | uint256 |
| `payRoyalty` | payable | tx receipt |
| `claimRoyalties` | write | result / revert |
| `getRoyalty` | view | address nftContract, uint256 tokenId, address creator, uint256 royaltyBps, uint256 totalEarned |

### Events

| Event | Signature |
|---|---|
| `OwnershipTransferred` | (address indexed previousOwner, address indexed newOwner) |
| `RoyaltyRegistered` | (uint256 indexed rid, address indexed nftContract, uint256 tokenId, address indexed creator, uint256 bps) |
| `RoyaltyPaid` | (uint256 indexed rid, address indexed from, address indexed to, uint256 amount) |
| `RoyaltyClaimed` | (uint256 indexed rid, address indexed creator, uint256 amount) |

## Network

| | |
|---|---|
| Chain | BOT Chain Mainnet (chainId `677`) |
| RPC | `https://rpc.botchain.ai` |
| Explorer | `https://scan.botchain.ai` |
| Native currency | BOT (18 decimals) |
| Testnet | BOT Chain Testnet (chainId `968`) - `https://rpc.bohr.life` |

## Frontend

- **Wallet connection** - [Reown/AppKit](https://reown.com) (Web3Modal v2, inline modal, `subscribeAccount` / `subscribeNetwork`)
- **Web3 library** - ethers.js v6 (`BrowserProvider`, `Contract`, `parseEther`)
- **Animation** - GSAP 3 + ScrollTrigger (`expo.out` entrances, `prefers-reduced-motion` fallback renders content instantly)
- **Zero build step** - single `index.html`, CDN imports via ESM import map; no bundler, no framework runtime
- **Accessibility** - auto-generated `aria-label`s on all binary and form controls, focus-visible styles, button busy states

## Run it locally

```bash
git clone https://github.com/Henoch4/nft-royalty-registry.git
cd nft-royalty-registry
# open the frontend directly (no build step)
start frontend/index.html   # Windows
# or serve it if your browser blocks file:// modules:
npx serve frontend
```

> **Note** — contract addresses: the UI reads its deploy target from the `CA` constant at the top of the inline script. Until the contract is deployed to mainnet 677, the demo runs against the deterministic sample data built into the page; after deployment, set `CA['677']` to the real address and every button goes live.