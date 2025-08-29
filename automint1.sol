// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title AutoMintVault with built-in ERC20 token
contract AutoMintVault is ERC20, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;
    uint256 public immutable unlockTime;
    uint256 public constant TOKEN_PRICE_USD = 16e17; // $1.6 per token

    constructor(
        string memory _name,
        string memory _symbol,
        address _usdc,
        uint256 _unlockTime
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC");
        require(_unlockTime > block.timestamp, "Unlock must be future");

        usdc = IERC20(_usdc);
        unlockTime = _unlockTime;
    }

    /// @notice Deposit USDC and mint vault tokens at $1.6 per token
    function depositAndMint(uint256 usdcAmount) external nonReentrant {
        require(usdcAmount > 0, "Amount > 0");

        // Transfer USDC from sender to vault
        usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);

        // Calculate how many vault tokens to mint
        uint256 tokensToMint = (usdcAmount * 1e18) / TOKEN_PRICE_USD;

        // Mint tokens directly to sender
        _mint(msg.sender, tokensToMint);
    }

    /// @notice Owner can withdraw all USDC after unlock
    function withdrawUSDC() external onlyOwner nonReentrant {
        require(block.timestamp >= unlockTime, "Vault locked");
        uint256 balance = usdc.balanceOf(address(this));
        require(balance > 0, "No USDC to withdraw");
        usdc.safeTransfer(owner(), balance);
    }

    /// @notice View USDC balance in vault
    function getUSDCBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
} // <-- make sure this closing brace exists
