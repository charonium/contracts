
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
 * @dev Contract for managing a whitelist of addresses using BitMaps
 */
library LetheWhitelist{
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _whitelist;

    event AddedToWhitelist(address indexed account);

    // /**
    //  * @dev Initializes the contract and adds the initial owner to the whitelist
    //  * @param initialOwner The address to be set as the initial owner and added to the whitelist
    //  */
    // constructor(address initialOwner) Ownable(initialOwner) {
    //     _addToWhitelist(initialOwner);
    // }

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
