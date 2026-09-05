// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AKAMToken is ERC20, Ownable, ReentrancyGuard {
    // ============ Constants ============
    uint256 public constant INITIAL_SUPPLY = 400_000_000 * 10**18; // 400 million
    uint256 public constant ALLOCATION_PER_WALLET = 40_000_000 * 10**18; // 40 million
    uint256 public constant NUMBER_OF_WALLETS = 10;
    
    // Burn mechanism
    uint256 public constant NORMAL_BURN_PERCENT = 1; // 1%
    uint256 public constant MYSTERY_BURN_PERCENT = 10; // 10%
    uint256 public constant MYSTERY_CHANCE = 1; // 1% probability
    
    // Gas sponsorship
    uint256 public gasFeeInAKAM = 10 * 10**18; // 10 AKAM per transaction
    bool public isGasSponsored = false;
    
    // ============ State Variables ============
    address[10] public controlledWallets;
    uint256 public walletCount = 0;
    
    // ============ Events ============
    event WalletRegistered(address indexed wallet, uint256 index);
    event MysteryBurn(address indexed sender, uint256 burnedAmount);
    event NormalBurn(address indexed sender, uint256 burnedAmount);
    event GasFeePaid(address indexed user, uint256 amount);
    event GasSponsored(address indexed user);
    event GasFeeUpdated(uint256 newFee);
    event GasSponsorshipToggled(bool status);

    // ============ Constructor ============
    constructor(address[10] memory _wallets) 
        ERC20("AKAM Token", "AKAM") 
        Ownable(msg.sender) 
    {
        // Mint total supply to owner first
        _mint(msg.sender, INITIAL_SUPPLY);
        
        // Distribute to 10 wallets
        for (uint256 i = 0; i < NUMBER_OF_WALLETS; i++) {
            require(_wallets[i] != address(0), "Invalid wallet address");
            controlledWallets[i] = _wallets[i];
            _transfer(msg.sender, _wallets[i], ALLOCATION_PER_WALLET);
            emit WalletRegistered(_wallets[i], i);
        }
        
        walletCount = NUMBER_OF_WALLETS;
    }

    // ============ Transfer with Burn Mechanism ============
    function _transfer(address from, address to, uint256 amount) internal override {
        // Skip burn for contract operations
        if (from == address(0) || to == address(0)) {
            super._transfer(from, to, amount);
            return;
        }
        
        uint256 burnAmount;
        
        // Determine burn type
        if (_isMysteryBurn()) {
            burnAmount = amount * MYSTERY_BURN_PERCENT / 100;
            emit MysteryBurn(from, burnAmount);
        } else {
            burnAmount = amount * NORMAL_BURN_PERCENT / 100;
            emit NormalBurn(from, burnAmount);
        }
        
        uint256 transferAmount = amount - burnAmount;
        
        // Burn tokens
        super._transfer(from, address(0), burnAmount);
        // Transfer remaining
        super._transfer(from, to, transferAmount);
    }

    // ============ Gas Sponsorship System ============
    
    /// @notice Transfer with gas fee paid in AKAM
    function transferWithGasFee(address to, uint256 amount) public nonReentrant returns (bool) {
        require(balanceOf(msg.sender) >= amount + gasFeeInAKAM, "Insufficient balance");
        
        if (!isGasSponsored) {
            // User pays gas fee in AKAM
            super._transfer(msg.sender, owner(), gasFeeInAKAM);
            emit GasFeePaid(msg.sender, gasFeeInAKAM);
        } else {
            // Gas is sponsored (free for user)
            emit GasSponsored(msg.sender);
        }
        
        // Execute transfer with burn mechanism
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfer from with gas fee paid in AKAM
    function transferFromWithGasFee(
        address from, 
        address to, 
        uint256 amount
    ) public nonReentrant returns (bool) {
        require(balanceOf(from) >= amount + gasFeeInAKAM, "Insufficient balance");
        
        if (!isGasSponsored) {
            super._transfer(from, owner(), gasFeeInAKAM);
            emit GasFeePaid(from, gasFeeInAKAM);
        } else {
            emit GasSponsored(from);
        }
        
        _spendAllowance(from, msg.sender, amount + gasFeeInAKAM);
        _transfer(from, to, amount);
        return true;
    }

    // ============ Mystery Burn Logic ============
    function _isMysteryBurn() internal view returns (bool) {
        uint256 random = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            block.number
        ))) % 100;
        
        return random < MYSTERY_CHANCE;
    }

    // ============ Wallet Management ============
    
    /// @notice Get all controlled wallets
    function getControlledWallets() public view returns (address[10] memory) {
        return controlledWallets;
    }
    
    /// @notice Check if address is a controlled wallet
    function isControlledWallet(address wallet) public view returns (bool) {
        for (uint256 i = 0; i < NUMBER_OF_WALLETS; i++) {
            if (controlledWallets[i] == wallet) {
                return true;
            }
        }
        return false;
    }

    // ============ Owner Functions ============
    
    /// @notice Update gas fee amount
    function setGasFee(uint256 newFee) public onlyOwner {
        gasFeeInAKAM = newFee;
        emit GasFeeUpdated(newFee);
    }
    
    /// @notice Toggle gas sponsorship
    function setGasSponsored(bool sponsored) public onlyOwner {
        isGasSponsored = sponsored;
        emit GasSponsorshipToggled(sponsored);
    }
    
    /// @notice Emergency function to recover tokens sent to contract
    function recoverTokens(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(this), "Cannot recover AKAM");
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    // ============ View Functions ============
    
    /// @notice Get current burn statistics
    function getBurnInfo() public pure returns (
        uint256 normalBurnPercent,
        uint256 mysteryBurnPercent,
        uint256 mysteryChance
    ) {
        return (NORMAL_BURN_PERCENT, MYSTERY_BURN_PERCENT, MYSTERY_CHANCE);
    }
    
    /// @notice Get token info
    function getTokenInfo() public view returns (
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 decimals,
        uint256 gasFee,
        bool gasSponsored
    ) {
        return (
            name(),
            symbol(),
            totalSupply(),
            decimals(),
            gasFeeInAKAM,
            isGasSponsored
        );
    }
}
