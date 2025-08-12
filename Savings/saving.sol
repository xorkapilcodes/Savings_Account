// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SimpleSavingsAccount
 * @dev A basic savings account contract with compound interest
 * @author Your Name
 */
contract SimpleSavingsAccount {
    
    // User account structure
    struct Account {
        uint256 balance;           // Current balance including interest
        uint256 lastUpdateTime;    // Last time interest was calculated
    }
    
    // State variables
    mapping(address => Account) public accounts;
    uint256 public constant ANNUAL_INTEREST_RATE = 500; // 5% APY in basis points
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 * 24 * 60 * 60;
    
    // Events
    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed user, uint256 amount, uint256 remainingBalance);
    event InterestAdded(address indexed user, uint256 interest, uint256 newBalance);
    
    /**
     * @dev Deposit ETH into savings account
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        
        // Update interest before deposit
        _updateInterest(msg.sender);
        
        // Add deposit to balance
        accounts[msg.sender].balance += msg.value;
        accounts[msg.sender].lastUpdateTime = block.timestamp;
        
        emit Deposited(msg.sender, msg.value, accounts[msg.sender].balance);
    }
    
    /**
     * @dev Withdraw funds from savings account
     * @param amount Amount to withdraw in wei
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        
        // Update interest before withdrawal
        _updateInterest(msg.sender);
        
        require(accounts[msg.sender].balance >= amount, "Insufficient balance");
        
        // Deduct from balance
        accounts[msg.sender].balance -= amount;
        accounts[msg.sender].lastUpdateTime = block.timestamp;
        
        // Transfer ETH to user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount, accounts[msg.sender].balance);
    }
    
    /**
     * @dev Get current balance including accrued interest
     * @param user Address of the account holder
     * @return Current balance with interest
     */
    function getBalance(address user) external view returns (uint256) {
        Account memory account = accounts[user];
        if (account.balance == 0) return 0;
        
        return account.balance + _calculateInterest(user);
    }
    
    /**
     * @dev Update interest for user account
     * @param user Address of the account holder
     */
    function updateInterest(address user) external {
        _updateInterest(user);
    }
    
    /**
     * @dev Internal function to calculate interest
     * @param user Address of the account holder
     * @return Calculated interest amount
     */
    function _calculateInterest(address user) internal view returns (uint256) {
        Account memory account = accounts[user];
        if (account.balance == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - account.lastUpdateTime;
        if (timeElapsed == 0) return 0;
        
        // Simple compound interest: Interest = Principal * Rate * Time
        uint256 interest = (account.balance * ANNUAL_INTEREST_RATE * timeElapsed) / 
                          (BASIS_POINTS * SECONDS_PER_YEAR);
        
        return interest;
    }
    
    /**
     * @dev Internal function to update interest for an account
     * @param user Address of the account holder
     */
    function _updateInterest(address user) internal {
        uint256 interest = _calculateInterest(user);
        
        if (interest > 0) {
            accounts[user].balance += interest;
            emit InterestAdded(user, interest, accounts[user].balance);
        }
        
        accounts[user].lastUpdateTime = block.timestamp;
    }
}
