// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title USDCSavingsVault
 * @author pr-approved
 * @notice A simple time-locked savings vault for USDC.
 *         Deposit USDC, set an unlock date, and you cannot
 *         withdraw until that date arrives. On-chain commitment device.
 *
 * Deployed on Ethereum Mainnet
 * USDC Contract: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract USDCSavingsVault {

    // ── State ────────────────────────────────────────────────────────────────

    IERC20 public immutable usdc;       // USDC token contract
    address public immutable owner;     // only owner can deposit / withdraw
    uint256 public unlockDate;          // unix timestamp — vault opens after this
    uint256 public depositedAmount;     // total USDC locked (in 6-decimal units)
    bool    public withdrawn;           // guard against double-withdraw

    // ── Events ───────────────────────────────────────────────────────────────

    event Deposited(address indexed depositor, uint256 amount, uint256 unlockDate);
    event Withdrawn(address indexed to, uint256 amount);
    event UnlockDateExtended(uint256 oldDate, uint256 newDate);

    // ── Constructor ──────────────────────────────────────────────────────────

    /**
     * @param _usdcAddress  Address of the USDC token contract on your chain
     * @param _unlockDate   Unix timestamp when the vault unlocks
     *                      Tip: use https://www.unixtimestamp.com to convert a date
     */
    constructor(address _usdcAddress, uint256 _unlockDate) {
        require(_unlockDate > block.timestamp, "Unlock date must be in the future");
        usdc    = IERC20(_usdcAddress);
        owner   = msg.sender;
        unlockDate = _unlockDate;
    }

    // ── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the vault owner");
        _;
    }

    // ── Core Functions ───────────────────────────────────────────────────────

    /**
     * @notice Deposit USDC into the vault.
     *         You must approve this contract to spend your USDC first.
     *         Amount is in USDC's 6-decimal units — e.g. 10 USDC = 10_000_000
     */
    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0,       "Amount must be greater than 0");
        require(!withdrawn,       "Vault has already been withdrawn");
        require(
            usdc.transferFrom(msg.sender, address(this), amount),
            "USDC transfer failed — did you approve this contract?"
        );
        depositedAmount += amount;
        emit Deposited(msg.sender, amount, unlockDate);
    }

    /**
     * @notice Withdraw all USDC once the unlock date has passed.
     *         Reverts if the vault is still locked.
     */
    function withdraw() external onlyOwner {
        require(block.timestamp >= unlockDate, "Vault is still locked — be patient");
        require(!withdrawn,                    "Already withdrawn");
        require(depositedAmount > 0,           "Nothing to withdraw");

        uint256 amount  = depositedAmount;
        withdrawn       = true;
        depositedAmount = 0;

        require(usdc.transfer(owner, amount), "USDC transfer failed");
        emit Withdrawn(owner, amount);
    }

    /**
     * @notice Extend the lock period — you can push the date further out
     *         but you can never move it earlier (no cheating).
     */
    function extendLock(uint256 newUnlockDate) external onlyOwner {
        require(newUnlockDate > unlockDate, "New date must be later than current unlock date");
        require(!withdrawn,                 "Vault already withdrawn");
        uint256 old = unlockDate;
        unlockDate  = newUnlockDate;
        emit UnlockDateExtended(old, newUnlockDate);
    }

    // ── View Functions ───────────────────────────────────────────────────────

    /// @notice Seconds remaining until the vault unlocks (0 if already unlocked)
    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= unlockDate) return 0;
        return unlockDate - block.timestamp;
    }

    /// @notice True if the vault is still locked
    function isLocked() external view returns (bool) {
        return block.timestamp < unlockDate;
    }

    /// @notice Human-readable USDC balance (divided by 10^6)
    function getBalanceUSDC() external view returns (uint256) {
        return depositedAmount / 1_000_000;
    }
}
