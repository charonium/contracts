// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./LetheWhitelist.sol";

/**
 * @title LETHE TOKEN CONTRACT
 * @dev Implements an ERC20 token with initial transfer restrictions and one-time transition to unrestricted transfers
 */
contract Lethe is ERC20, ERC20Permit, Ownable, ERC20Burnable {
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _whitelist;

    bool public transfersEnabled;

    event TransfersEnabled();
    event AddedToWhitelist(address indexed account);

    /**
     * @dev Constructor to initialize the Lethe token
     */
    constructor() ERC20("Lethe", "LETHE") ERC20Permit("Lethe") Ownable(msg.sender) {
        _mint(msg.sender, 690_000_000 ether);
        _addToWhitelist(msg.sender);
    }

    /**
     * @dev Enables transfers for all addresses permanently
     * @notice This function can only be called once by the owner
     */
    function makeTransferable() external onlyOwner {
        require(!transfersEnabled, "Transfers are already enabled");
        transfersEnabled = true;
        emit TransfersEnabled();
        delete _whitelist;
    }

    /**
     * @dev Internal function to update token balances with transfer restrictions
     * @param from Address tokens are transferred from
     * @param to Address tokens are transferred to
     * @param value Amount of tokens transferred
     */
    function _update(address from, address to, uint256 value) internal override {
        if (!transfersEnabled) {
            require(from == address(0) || to == address(0) ||
                isWhitelisted(from) || isWhitelisted(to),
                "Transfer not allowed: address not whitelisted");
        }
        super._update(from, to, value);
    }

        /**
     * @dev Adds an account to the whitelist. Can only be called by the owner.
     * @param account The address to be added to the whitelist
     */
    function addToWhitelist(address account) external {
        _addToWhitelist(account);
    }

    /**
     * @dev Internal function to add an account to the whitelist
     * @param account The address to be added to the whitelist
     */
    function _addToWhitelist(address account) private {
        _whitelist.set(uint160(account));
        emit AddedToWhitelist(account);
    }

    /**
     * @dev Checks if an account is whitelisted
     * @param account The address to check
     * @return bool True if the account is whitelisted, false otherwise
     */
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist.get(uint160(account));
    }
}