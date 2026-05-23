# Process — How This Was Built

*End to end process for deploying a USDC savings vault on Ethereum mainnet. Written for PMs and developers who want to understand the full flow, not just the happy path.*

---

## The full journey

```
Write contract in Solidity
        ↓
Compile (fix errors)
        ↓
Deploy to Sepolia testnet (free)
        ↓
Get test ETH + test USDC
        ↓
Approve vault to spend test USDC
        ↓
Deposit test USDC
        ↓
Test withdrawal rejection ✅
        ↓
Deploy to Ethereum mainnet (real money)
        ↓
Bridge real USDC to mainnet, if needed (Base → Ethereum)
        ↓
Approve vault to spend real USDC
        ↓
Deposit 5 real USDC
        ↓
Confirm on Etherscan ✅
        ↓
5 USDC locked until March 2 2030 🔒
```

---

## Phase 1 — Writing the contract

**Tool:** Remix IDE (remix.ethereum.org) — browser based, no install needed

**Language:** Solidity 0.8.x

**Key design decisions:**
- `immutable` for owner and USDC address — set once in constructor, saves gas
- `onlyOwner` modifier on deposit, withdraw, extendLock — nobody else can touch it
- Separate `withdrawn` boolean — prevents double-withdraw attacks
- `extendLock` can only push date further out, never earlier — no cheating
- 6 decimal handling for USDC — 10 USDC = 10,000,000 units

**Errors encountered:**
- Em dash character (—) in error string broke compilation → replaced with plain hyphen (-)
- Compiler version `^0.8.20` not recognised in some IDEs → changed to `^0.8.0`

---

## Phase 2 — Compiling

**In Remix:**
1. Open Solidity Compiler tab (second icon, left sidebar)
2. Set compiler to `0.8.x`
3. Click Compile
4. Green checkmark = success

**Common errors:**
- Unicode characters in strings → use plain ASCII only
- Missing semicolons → Solidity requires them everywhere
- Wrong compiler version → check pragma matches IDE version

---

## Phase 3 — Deploying to Sepolia testnet

**Why testnet first:** Mistakes are free. Same code, same flow, no real money at risk.

**What you need:**
- MetaMask switched to Sepolia network
- Sepolia test ETH (from cloud.google.com/application/web3/faucet/ethereum/sepolia)
- Sepolia test USDC (from faucet.circle.com)

**Constructor arguments:**
```
_usdcAddress: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238  ← Sepolia USDC
_unlockDate:  [unix timestamp in the future]
```

**Get unix timestamp:** unixtimestamp.com → pick date → copy number

**Errors encountered:**
- Deployed with past timestamp → contract rejected with "Unlock date must be in the future"
- Deployed with wrong USDC address → deposit silently failed with "transfer amount exceeds balance"
- Both required full redeployment — no fixing after the fact

---

## Phase 4 — The approve → deposit two-step

This is the most important flow to understand. ERC-20 tokens require explicit authorisation before any contract can move them.

```
Step 1 — APPROVE
You → USDC contract:
"I authorise vault at 0x3E04... to spend up to 10 USDC"
        ↓
Step 2 — DEPOSIT
Vault contract → USDC contract:
"transferFrom owner to vault: 10 USDC"
        ↓
USDC contract checks: is vault approved for this amount?
        ↓ YES
Transfer executes. USDC moves from wallet row to vault row in ledger.
```

**How to approve:**
- Go to Etherscan → token contract → Write as Proxy tab
- Find `approve` function
- `spender` = your vault contract address
- `value` = amount in 6-decimal units (10 USDC = 10000000)
- Click Write → confirm MetaMask

**Critical:** Every new contract deployment needs a fresh approval. The approval is tied to a specific contract address.

---

## Phase 5 — Testing on Sepolia

**Functions to test:**

| Function | Expected result |
|---|---|
| `getBalanceUSDC` | Returns deposited amount |
| `isLocked` | Returns true |
| `getTimeRemaining` | Returns seconds until unlock |
| `withdraw` | Reverts: "Vault is still locked — be patient" |
| `owner` | Returns your wallet address |

**Withdrawal test on Sepolia:**
- Called withdraw before unlock date
- Got exact revert message in console: "Vault is still locked — be patient" ✅

---

## Phase 6 — Deploying to Ethereum mainnet

**Constructor arguments:**
```
_usdcAddress: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48  ← mainnet USDC
_unlockDate:  1898658000  ← March 2 2030
```

**Gas cost:** $0.35 at 0.165 Gwei (historically low)

**Deployed contract:** `0x005119Cf038E5645B0496810466e194D3D783137`

---

## Phase 7 — Bridging USDC to mainnet

**Problem:** USDC was on Base, not Ethereum mainnet. Same token, different chain, incompatible without bridging.

**Solution:** CCTP (Circle's Cross-Chain Transfer Protocol)

```
Base USDC → CCTP bridge → Ethereum Mainnet USDC
6 USDC sent → 6 USDC received (no fee, ~25 mins)
```

**Alternative bridges (faster, small fee):**
- Across (~2 seconds, $0.03 fee)
- Relay (~10 seconds, $0.04 fee)

**Key insight:** USDC is not one asset. It exists on multiple chains simultaneously, each with a different contract address. Always verify which chain your assets are on before planning mainnet interactions.

---

## Phase 8 — Mainnet deposit

**Approve on mainnet:**
- Etherscan → USDC mainnet contract → Write as Proxy
- `approve(0x005119Cf..., 5000000)` → 5 USDC
- Confirmed ✅

**Deposit in Remix:**
- `deposit(5000000)` → 5 USDC
- Gas: $0.02
- Confirmed ✅

---

## Phase 9 — Withdrawal attempt (mainnet)

**What happened:**
- Tried to call `withdraw()` on mainnet contract
- MetaMask Smart Transaction feature simulated the transaction locally
- Detected it would fail (vault locked until 2030)
- Cancelled automatically before hitting the blockchain
- Gas fee: $0.00

**Note:** On Sepolia the exact revert message appeared in console. On mainnet MetaMask's simulation caught it first — the revert message never surfaced because the transaction never broadcast.

---

## USDC contract addresses by chain

| Chain | USDC Address |
|---|---|
| Ethereum Mainnet | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| Sepolia Testnet | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` |
| Base | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Polygon | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` |
| Arbitrum | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` |

---

## Tools used

| Tool | Purpose | URL |
|---|---|---|
| Remix IDE | Write, compile, deploy Solidity | remix.ethereum.org |
| MetaMask | Wallet, transaction signing | metamask.io |
| Etherscan | Block explorer, contract interaction | etherscan.io |
| Sepolia Etherscan | Testnet block explorer | sepolia.etherscan.io |
| unixtimestamp.com | Convert dates to unix timestamps | unixtimestamp.com |
| Google Cloud Web3 Faucet | Free Sepolia test ETH | cloud.google.com/application/web3/faucet |
| Circle Faucet | Free Sepolia test USDC | faucet.circle.com |
| CCTP / Relay | Bridge USDC across chains | relay.link |

---

## Final state

```
Contract:     0x005119Cf038E5645B0496810466e194D3D783137
Network:      Ethereum Mainnet
Locked:       5 USDC
Unlock date:  March 2 2030 (unix: 1898658000)
Total cost:   $0.36
Etherscan:    https://etherscan.io/address/0x005119Cf038E5645B0496810466e194D3D783137
```
