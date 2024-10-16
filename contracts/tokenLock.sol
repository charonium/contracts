// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CHARONIUM TOKEN LOCK
 * @dev Contract for locking and releasing ERC20 tokens
 */
contract TokenLock is Ownable {
    IERC20 public token;

    struct Lock {
        uint256 id;
        string title;
        uint256 amount;
        uint256 unlockTime;
        address beneficiary;
    }

    /** @dev Mapping of user addresses to their respective locks
    *** @param address => Lock[]
    **/
    mapping(address => Lock[]) public locks;
    uint256 private nextLockId = 1; // Counter for generating unique lock IDs

    event TokensLocked(address indexed sender, address indexed beneficiary, uint256 id, string title, uint256 amount, uint256 unlockTime);
    event TokensWithdrawn(address indexed beneficiary, uint256 id, uint256 amount, uint256 when);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }
    /** @dev Locks tokens for a specified duration and beneficiary
    *** @param amount Number of tokens to lock
    *** @param _unlockTime Timestamp when tokens can be withdrawn
    *** @param _title Title of the lock
    *** @param _beneficiary Address that can withdraw the tokens
    **/
    function lockTokens(uint256 amount, uint256 _unlockTime, string memory _title, address _beneficiary) external {
        require(block.timestamp < _unlockTime, "Unlock time should be in the future");
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 lockId = nextLockId++;
        locks[_beneficiary].push(Lock(lockId, _title, amount, _unlockTime, _beneficiary));
        emit TokensLocked(msg.sender, _beneficiary, lockId, _title, amount, _unlockTime);
    }

    /** @dev Allows a beneficiary to withdraw tokens from a specific lock
     * @param _id The unique identifier of the lock to withdraw from
     */
    function withdrawSpecific(uint256 _id) external {
        // Get locks of caller
        Lock[] storage userLocks = locks[msg.sender];
        require(userLocks.length > 0, "No tokens locked for this address");

        // find matching lock ID
        for (uint256 i = 0; i < userLocks.length; i++) {
            if (userLocks[i].id == _id) {
                require(block.timestamp >= userLocks[i].unlockTime, "Tokens are still locked");
                require(msg.sender == userLocks[i].beneficiary, "Only beneficiary can withdraw");
                uint256 amount = userLocks[i].amount;
                require(token.transfer(msg.sender, amount), "Transfer failed");

                // Remove lock by swapping with last element and popping
                userLocks[i] = userLocks[userLocks.length - 1];
                userLocks.pop();

                emit TokensWithdrawn(msg.sender, _id, amount, block.timestamp);
                return;
            }
        }

        revert("Lock not found");
    }

    function viewLockedTokens(address _address) external view returns (Lock[] memory) {
        return locks[_address];
    }

    function withdrawFunds() external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}
