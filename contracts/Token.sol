// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

/**
 * @title Test Token with Dividend Distribution
 * @author —
 * @dev
 *  - Simple ERC20-like token backed by ETH
 *  - Token amount == wei deposited
 *  - Supports mint, burn, transfer, and allowance
 *  - Maintains an on-chain holder list (1-based indexing)
 *  - Dividends are distributed proportionally to holders
 *  - Past dividends remain withdrawable even after selling/burning tokens
 */

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token {

    /* ───────────────── BASIC TOKEN DATA ───────────────── */

    /// @dev Token name
    string public constant name = "Test token";

    /// @dev Token symbol
    string public constant symbol = "TEST";

    /// @dev Token decimals (ERC20-compatible)
    uint8 public constant decimals = 18;

    /// @dev Total token supply
    uint256 public totalSupply;

    /* ───────────────── ERC20 STORAGE ───────────────── */

    /// @dev Token balances per address
    mapping(address => uint256) private balances;

    /// @dev Allowance mapping (owner => spender => amount)
    mapping(address => mapping(address => uint256)) private allowances;

    /* ───────────────── HOLDER TRACKING ───────────────── */

    /**
     * @dev Array of current token holders.
     * Used only for dividend distribution.
     * Indexing is 1-based when accessed externally.
     */
    address[] private holders;

    /// @dev Quick lookup to know if address is a holder
    mapping(address => bool) private isHolder;

    /**
     * @dev Adds an address to the holder list if not already present.
     */
    function _addHolder(address account) internal {
        if (!isHolder[account]) {
            holders.push(account);
            isHolder[account] = true;
        }
    }

    /**
     * @dev Removes an address from the holder list if balance becomes zero.
     * Uses swap-and-pop to keep array compact.
     */
    function _removeHolder(address account) internal {
        if (!isHolder[account]) return;

        uint256 len = holders.length;
        for (uint256 i = 0; i < len; i++) {
            if (holders[i] == account) {
                holders[i] = holders[len - 1];
                holders.pop();
                isHolder[account] = false;
                break;
            }
        }
    }

    /**
     * @dev Returns number of current token holders.
     */
    function getNumTokenHolders() external view returns (uint256) {
        return holders.length;
    }

    /**
     * @dev Returns holder address at 1-based index.
     * @param index 1-based index (index >= 1)
     */
    function getTokenHolder(uint256 index) external view returns (address) {
        require(index >= 1 && index <= holders.length, "Invalid index");
        return holders[index - 1];
    }

    /* ───────────────── ERC20 CORE ───────────────── */

    /**
     * @dev Returns token balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Returns allowance amount.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    /**
     * @dev Approves spender to spend tokens.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    /**
     * @dev Transfers tokens to another address.
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Transfers tokens using allowance mechanism.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowances[from][msg.sender];
        require(allowed >= amount, "Allowance exceeded");

        allowances[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Internal transfer logic with holder bookkeeping.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "Insufficient balance");

        balances[from] -= amount;
        balances[to] += amount;

        if (balances[to] > 0) _addHolder(to);
        if (balances[from] == 0) _removeHolder(from);
    }

    /* ───────────────── MINT & BURN ───────────────── */

    /**
     * @dev Mints tokens by sending ETH.
     * Token amount minted equals msg.value.
     */
    function mint() external payable {
        require(msg.value > 0, "Zero mint");

        balances[msg.sender] += msg.value;
        totalSupply += msg.value;

        _addHolder(msg.sender);
    }

    /**
     * @dev Burns all tokens of caller and sends ETH to target address.
     * @param to Address receiving the burned ETH value
     */
    function burn(address payable to) external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to burn");

        balances[msg.sender] = 0;
        totalSupply -= amount;

        _removeHolder(msg.sender);

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH transfer failed");
    }

    /* ───────────────── DIVIDENDS ───────────────── */

    /// @dev Accumulated but not withdrawn dividends per address
    mapping(address => uint256) private withdrawableDividends;

    /**
     * @dev Records a dividend payout.
     * ETH is distributed proportionally to current holders.
     */
    function recordDividend() external payable {
        require(msg.value > 0, "Empty dividend");
        require(totalSupply > 0, "No supply");

        for (uint256 i = 0; i < holders.length; i++) {
            address h = holders[i];
            uint256 share = (msg.value * balances[h]) / totalSupply;
            withdrawableDividends[h] += share;
        }
    }

    /**
     * @dev Returns withdrawable dividend amount for an account.
     */
    function getWithdrawableDividend(address account) external view returns (uint256) {
        return withdrawableDividends[account];
    }

    /**
     * @dev Withdraws accumulated dividends to a target address.
     */
    function withdrawDividend(address payable to) external {
        uint256 amount = withdrawableDividends[msg.sender];
        require(amount > 0, "No dividend");

        withdrawableDividends[msg.sender] = 0;

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH transfer failed");
    }
}
