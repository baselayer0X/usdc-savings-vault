# Learnings — USDC Savings Vault

*Built by a FinTech PM who wanted to understand smart contract infrastructure from the inside, not just the spec. These are the honest lessons — including the mistakes — framed through a product lens.*

---

## The mistakes first

Because the mistakes are where the real learning is.

Context for Mistake 1 - USDC is in itself a smart contract, deployed on Ethereum by Circle.
When Circle launched USDC on Ethereum they deployed a contract that:

- Keeps a ledger of who owns how much USDC
- Handles transfers between wallets
- Handles approvals
- Allows Circle to mint and burn USDC

That contract lives at a permanent address on Ethereum:
0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

### Mistake 1 — Wrong USDC contract address
Deployed the contract pointing at an incorrect USDC address on Sepolia. The contract compiled, deployed, and accepted transactions — but silently refused to move any funds. The error "transfer amount exceeds balance" gave no indication the problem was the contract address, not my wallet balance.

**What I learned:** Contract addresses are immutable after deployment and incorrect addresses cannot be modified. There's no "update config in production.", and the contract needs to be re-deployed with the new cost. The equivalent in traditional payments would be hardcoding the wrong bank routing number into a payment processor and having no way to fix it without a full redeployment. Spec quality before deployment is a different category of discipline than spec quality in traditional software.

This mistake cost me nothing since this was a mistake on Sepolia testnet with fake ETH.

---

### Mistake 2 — Unix timestamp in the past
Tried to deploy with an unlock date that had already passed. The contract caught it with a require() check and rejected the deployment. Cost: zero, because I was on testnet.

**What I learned:** Time handling in smart contracts is unforgiving in a way that payment systems often aren't. We build date logic with the assumption that someone can fix a value date error after the fact. On-chain that assumption doesn't exist. The forcing function of immutability makes you verify inputs more carefully before you submit - this is a discipline that would improve a lot of payment spec work I've done.

---

### Mistake 3 — Em dash in a Solidity string
A typographical em dash (—) inside an error message string broke compilation entirely. The Solidity compiler doesn't accept unicode characters in strings. One character, one failed build.

**What I learned:** Minor, but telling. The tools are unforgiving in ways that catch you off guard. Building tolerance for precise, exact specification — not approximately right, exactly right — is a muscle worth developing regardless of whether you're writing Solidity or writing a payment API spec.

---

### Mistake 4 — USDC on the wrong chain
When moving to mainnet, discovered my USDC was on Base not Ethereum mainnet. Same token name, different blockchain, completely incompatible without bridging.

**What I learned:** This is the most important mistake and the most relevant to payments product work. USDC is not one thing. It exists simultaneously across a dozen chains, each with a different contract address, different liquidity, different bridging requirements. A payment PM who thinks of USDC as a single asset is building products on an incomplete mental model. The chain is part of the asset identity.

---

## The PM insights

### 1. Authorisation and execution should always be separate

ERC-20 tokens enforce a two-step model: explicit approval first, transfer second. You cannot skip the approval step. The protocol won't allow it.

In traditional payments these two moments are frequently collapsed into one — and the operational complexity of chargebacks, disputes, and fraud exists largely because of that conflation. Explicit, on-chain, timestamped authorisation separate from execution is a better model. The friction is real. The clarity is worth it.

---

### 2. Settlement finality is a policy decision, not a technical constraint

Ethereum transaction finality is deterministic — confirmed blocks don't reverse. T+1 and T+2 in traditional rails are not technical constraints. They're policy decisions made when batch processing was the binding limitation. That limitation no longer exists. The policy remains because business models depend on it.

Every time a product team accepts "settlement is T+2, that's just how it works" without interrogating it — that's a product decision being made by default rather than by design.

---

### 3. Fee transparency is a design choice in traditional payments

Total cost to deploy this contract, approve USDC spend, and deposit funds on Ethereum mainnet: **$0.36**. Shown in full before each confirmation. No hidden fees, no spread, no correspondent charges disclosed after the fact.

Traditional payment fee structures are frequently opaque by design — not maliciously, but because the fee is distributed across multiple counterparties none of whom have full visibility. The result is users experiencing cost as confusion.

On-chain infrastructure makes opacity structurally impossible. Building for transparency before it's mandated is both a product and a trust decision.

---

### 4. Simulation before execution is an underrated product pattern

MetaMask's Smart Transaction feature simulated my withdrawal attempt locally before broadcasting it to the network. It detected the transaction would fail, cancelled it automatically, and charged me nothing.

Most payment systems charge the cost of a failed transaction — in fees, in ops time, in customer trust — after the failure. The simulation layer catches it before it becomes a problem.

This is not a blockchain-specific insight. It's a product pattern worth examining in any payment flow where failed transactions have a cost.

---

### 5. Immutability changes how you spec before you ship

A deployed smart contract cannot be patched. Bugs are permanent. Old versions remain on-chain forever, visible to anyone.

This forces a quality of pre-deployment thinking that optional rollback makes easy to skip. Not an argument for immutable payment infrastructure — flexibility has real value. But an argument for treating the ability to patch in production as a cost rather than a free option. It shows up in ops headcount, exception queues, and reconciliation processes that exist because specs weren't tight enough the first time.

---

## The numbers

| Action | Network | Cost |
|---|---|---|
| Contract deployment (attempt 1, failed) | Sepolia | $0.00 |
| Contract deployment (attempt 2, success) | Sepolia | $0.00 |
| USDC approval | Sepolia | $0.00 |
| USDC deposit (test) | Sepolia | $0.00 |
| Contract deployment | Ethereum Mainnet | $0.35 |
| USDC approval | Ethereum Mainnet | $0.01 |
| USDC deposit | Ethereum Mainnet | $0.02 |
| Withdrawal attempt (caught by MetaMask) | Ethereum Mainnet | $0.00 |
| **Total** | | **$0.36** |

---

## What I'd do differently

- Verify every contract address against Etherscan before deploying
- Verify unlock timestamps twice using two different converters
- Test on Sepolia with the exact same args planned for mainnet
- Check which chain assets are on before planning mainnet interactions
- Read the compiler error fully before assuming it's a logic error

All of these are spec discipline issues, not technical ones. The same discipline applies to payment product work.

---

## Contract details

| Field | Value |
|---|---|
| Network | Ethereum Mainnet |
| Contract address | `0x005119Cf038E5645B0496810466e194D3D783137` |
| Etherscan | https://etherscan.io/address/0x005119Cf038E5645B0496810466e194D3D783137 |
| Deployed | May 23 2026 |
| Amount locked | 5 USDC |
| Unlock date | March 2 2030 |
| Total cost | $0.36 |

---

*Written by a FinTech PM. Not a Solidity developer. The point was never to become one.*
