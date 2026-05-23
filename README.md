# USDC Savings Vault

A simple time-locked savings vault for USDC, deployed on Ethereum Mainnet.

Deposit USDC, set an unlock date, and you cannot withdraw until that date arrives.
No yield, no complexity — just an on-chain commitment device that enforces your own savings rules.

> Built as a personal learning project to understand smart contract deployment,
> ERC-20 token interactions, and on-chain state management.

---

## How it works

1. Deploy the contract with a USDC address and an unlock date
2. Approve the contract to spend your USDC (`approve()` on the USDC contract)
3. Call `deposit()` with your amount
4. Your USDC is locked until the unlock date — not even you can touch it before then
5. After the unlock date, call `withdraw()` to get your USDC back

---

## Contract details

| Field | Value |
|---|---|
| Network | Ethereum Mainnet |
| Solidity version | 0.8.20 |
| USDC address (Mainnet) | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| USDC decimals | 6 (10 USDC = 10,000,000 units) |
| Deployed address | *(add after deployment)* |
| Etherscan | *(add link after deployment)* |
| Transaction hash | *(add after deployment)* |

---

## Deploy it yourself (Remix IDE — no install needed)

### Step 1 — Open Remix
Go to [remix.ethereum.org](https://remix.ethereum.org) in your browser.

### Step 2 — Create the file
- In the file explorer (left panel), click the **+** icon
- Name it `USDCSavingsVault.sol`
- Paste the contract code in

### Step 3 — Compile
- Click the **Solidity Compiler** tab (second icon on left)
- Set compiler version to `0.8.20`
- Click **Compile USDCSavingsVault.sol**
- Green checkmark = success

### Step 4 — Get your unlock date as a Unix timestamp
- Go to [unixtimestamp.com](https://www.unixtimestamp.com)
- Pick your unlock date (e.g. 3 months from now)
- Copy the unix timestamp number (e.g. `1748000000`)

### Step 5 — Deploy
- Click the **Deploy & Run** tab (third icon on left)
- Set Environment to **Injected Provider - MetaMask**
- MetaMask will pop up — connect your wallet
- Under **Contract**, select `USDCSavingsVault`
- Fill in constructor params:
  - `_usdcAddress`: `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`
  - `_unlockDate`: your unix timestamp from step 4
- Click **Deploy** → confirm in MetaMask
- Copy the deployed contract address from the left panel

### Step 6 — Approve USDC spending
Before depositing, you need to tell the USDC contract to allow your vault to move your USDC.

- In Remix, load the USDC contract:
  - Under **At Address**, paste `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`
  - Use the IERC20 interface
- Call `approve(vaultAddress, amount)`
  - `vaultAddress` = your deployed contract address
  - `amount` = USDC amount in 6-decimal units (10 USDC = `10000000`)

### Step 7 — Deposit
- Back in your vault contract in Remix
- Call `deposit(10000000)` for 10 USDC
- Confirm in MetaMask
- Your USDC is now locked 🔒

---

## Key functions

| Function | What it does |
|---|---|
| `deposit(amount)` | Lock USDC into the vault |
| `withdraw()` | Withdraw after unlock date |
| `extendLock(newDate)` | Push unlock date further out (can never move earlier) |
| `isLocked()` | Returns true if still locked |
| `getTimeRemaining()` | Seconds until unlock |
| `getBalanceUSDC()` | Current balance in whole USDC |

---

## Lessons learned

- ERC-20 tokens require a two-step process: `approve()` then `transferFrom()` — the contract can't just take your tokens
- `block.timestamp` is how Solidity knows what time it is — it's the Unix timestamp of the current block
- USDC uses 6 decimal places, not 18 like ETH — `10 USDC = 10_000_000` not `10_000_000_000_000_000_000`
- The `immutable` keyword saves gas vs regular state variables for values set once in the constructor
- Reentrancy guards matter — the withdrawn flag prevents double-withdraw attacks

---

## USDC addresses by chain

| Chain | USDC Address |
|---|---|
| Ethereum Mainnet | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| Polygon | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` |
| Arbitrum | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` |
| Base | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |

---

## Test it on Sepolia first (recommended)

Before deploying on mainnet with real USDC, test on Sepolia testnet:
- Get free test ETH from [sepoliafaucet.com](https://sepoliafaucet.com)
- Get test USDC from [faucet.circle.com](https://faucet.circle.com)
- Deploy exactly the same way, just switch MetaMask to Sepolia network
- Zero real money at risk

---

## GitHub
[github.com/pr-approved](https://github.com/pr-approved)

Built May 2026
