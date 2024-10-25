// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/************************************************
 *                                              *
 *   ██████╗██╗  ██╗ █████╗ ██████╗  ██████╗    *
 *  ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗   *
 *  ██║     ███████║███████║██████╔╝██║   ██║   *
 *  ██║     ██╔══██║██╔══██║██╔══██╗██║   ██║   *
 *  ╚██████╗██║  ██║██║  ██║██║  ██║╚██████╔╝   *
 *   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝    *
 *                                              *
 *  ███╗   ██╗██╗██╗   ██╗███╗   ███╗           *
 *  ████╗  ██║██║██║   ██║████╗ ████║           *
 *  ██╔██╗ ██║██║██║   ██║██╔████╔██║           *
 *  ██║╚██╗██║██║██║   ██║██║╚██╔╝██║           *
 *  ██║ ╚████║██║╚██████╔╝██║ ╚═╝ ██║           *
 *  ╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝     ╚═╝           *
 *                                              *
 ************************************************
 *                                              *
 *  Token Contract for Lethe (LETHE)            *
 *  Version: 1.0.0                              *
 *  Author: TP                                  *
 *  License: MIT                                *
 *                                              *
 ************************************************/

/**
 * @title ICOContract
 * @dev Implements an Initial Coin Offering (ICO) contract for the Lethe token
 * @notice This contract manages the ICO process, including token sales, vesting, and claiming
 */
contract ICOContract is Ownable {
    IERC20 public token;
    uint256 public icoStartBlock;
    uint256 public icoEndBlock;
    bool public icoActive;
    bool public initialized;
    bool public paused;
    uint256 public constant VESTING_PERIOD = 240 days;
    uint256 private constant BLOCKS_PER_DAY = 43200; // Assuming 2 second block time

    AggregatorV3Interface private ethUsdPriceFeed;
    AggregatorV3Interface private eurUsdPriceFeed;

    // Token price in EUR (0.069 EUR)
    uint256 private constant TOKEN_PRICE_EUR = 69000000000000000;

    /**
     * @dev Struct to store vesting information for each participant
     */
    struct Vesting {
        uint256 totalAmount;
        uint256 startBlock;
        uint256 claimedAmount;
        uint256 lastClaimBlock;
    }

    mapping(address => Vesting) public vestings;
    TokenHolder public tokenHolder;

    /**
     * @dev Emitted when tokens are purchased during the ICO
     * @param purchaser Address of the token purchaser
     * @param amount Number of tokens purchased
     * @param value Amount of ETH spent
     */
    event TokensPurchased(address indexed purchaser, uint256 amount, uint256 value);

    /**
     * @dev Emitted when vested tokens are claimed
     * @param claimant Address of the token claimant
     * @param amount Number of tokens claimed
     */
    event TokensClaimed(address indexed claimant, uint256 amount);

    /**
     * @dev Emitted when the ICO is started
     * @param startTimestamp Block number when the ICO starts
     * @param endTimestamp Block number when the ICO ends
     */
    event IcoStarted(uint256 startTimestamp, uint256 endTimestamp);

    /**
     * @dev Emitted when the ICO is paused
     */
    event IcoPaused();

    /**
     * @dev Emitted when the ICO is resumed after being paused
     */
    event IcoResumed();

    /**
     * @dev Emitted when the ICO is ended
     */
    event IcoEnded();

    /**
     * @dev Emitted when unsold tokens are withdrawn by the owner
     * @param owner Address of the contract owner
     * @param amount Number of tokens withdrawn
     */
    event TokensWithdrawn(address indexed owner, uint256 amount);

    /**
     * @dev Constructor to initialize the ICOContract
     * @param _token Address of the Lethe token contract
     */
    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
        tokenHolder = new TokenHolder(_token, msg.sender);
        //ethUsdPriceFeed = AggregatorV3Interface(0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1); //Base Sepolia ETH/USD
        ethUsdPriceFeed = AggregatorV3Interface(0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70); //Base Mainnet ETH/USD
        eurUsdPriceFeed = AggregatorV3Interface(0xc91D87E81faB8f93699ECf7Ee9B44D11e1D53F0F); //Base Mainnet EUR/USD
    }

    /**
     * @dev Retrieves the current ETH/EUR exchange rate using Chainlink price feeds
     * @return The ETH/EUR rate with 8 decimal places
     */
    function getEthEurRate() public view returns (uint256) {
        (uint80 ethRoundId, int256 ethUsdPrice, , uint256 ethUpdatedAt, uint80 ethAnsweredInRound) = ethUsdPriceFeed.latestRoundData();
        (uint80 eurRoundId, int256 eurUsdPrice, , uint256 eurUpdatedAt, uint80 eurAnsweredInRound) = eurUsdPriceFeed.latestRoundData();

        require(ethRoundId == ethAnsweredInRound, "Stale price data");
        require(eurRoundId == eurAnsweredInRound, "Stale price data");
        require(ethUsdPrice > 0, "Invalid price data");
        require(eurUsdPrice > 0, "Invalid price data");
        require(block.timestamp - ethUpdatedAt <= 3600, "Price data too old");
        require(block.timestamp - eurUpdatedAt <= 350000, "Price data too old");

        // Chainlink 8 decimals
        return (uint256(ethUsdPrice) * 1e8) / uint256(eurUsdPrice);
        // return (uint256(ethUsdPrice) * 1e8) / uint256(109130000);
    }

    /**
     * @dev Initiates the ICO
     * @param endBlock The block number at which the ICO will end
     * @notice Can only be called by the contract owner and only once
     */
    function initiate(uint256 endBlock) external onlyOwner {
        require(!icoActive, "ICO is already active");
        require(!initialized, "ICO is already initialized");
        icoStartBlock = block.number;
        icoEndBlock = endBlock;
        icoActive = true;
        initialized = true;
        emit IcoStarted(icoStartBlock, icoEndBlock);
    }

    /**
     * @dev Pauses the ICO
     * @notice Can only be called by the contract owner when the ICO is active
     */
    function pause() external onlyOwner {
        require(icoActive, "ICO is not active");
        paused = true;
        emit IcoPaused();
    }

    /**
     * @dev Resumes the ICO after it has been paused
     * @notice Can only be called by the contract owner when the ICO is paused
     */
    function resume() external onlyOwner {
        require(!icoActive, "ICO is already active");
        require(paused, "ICO is not paused");
        paused = false;
        emit IcoResumed();
    }

    /**
     * @dev Ends the ICO and transfers remaining tokens to the owner
     * @notice Can only be called by the contract owner after the ICO end block
     */
    function end() external onlyOwner {
        require(block.number > icoEndBlock, "ICO has not ended yet");
        require(icoActive, "ICO is not active");

        //transfer remaining tokens to owner (vesting tokens are already in the tokenHolder contract)
        uint256 remainingTokens = token.balanceOf(address(this));
        if (remainingTokens > 0) {
            token.transfer(owner(), remainingTokens);
        }
        icoActive = false;
        emit IcoEnded();
    }

    /**
     * @dev Allows participants to contribute ETH and receive tokens
     * @notice Calculates token amount based on current ETH/EUR rate and transfers tokens
     */
    function contribute() external payable {
        require(icoActive, "ICO is not active");
        require(!paused, "ICO is paused");
        require(block.number <= icoEndBlock, "ICO has ended");
        require(vestings[msg.sender].totalAmount == 0, "You have already participated in the ICO");

        uint256 ethEurRate = getEthEurRate();
        // ethEurRate has 8 decimals, msg.value has 18 decimals
        // Multiply first, then divide to maintain precision
        uint256 eurValue = (msg.value * ethEurRate) / 1e18;

        // TOKEN_PRICE_EUR is in 18 decimals, eurValue is in 8 decimals
        // Multiply eurValue by 1e10 to match TOKEN_PRICE_EUR's precision
        uint256 tokensAmount = (eurValue * 1e10 * 1e18) / TOKEN_PRICE_EUR;
        require(tokensAmount > 0, "No tokens purchased");
        require(tokensAmount <= token.balanceOf(address(this)), "Not enough tokens available");

        uint256 initialReleaseAmount = tokensAmount / 3;
        uint256 vestingAmount = tokensAmount - initialReleaseAmount;

        Vesting storage vesting = vestings[msg.sender];
        vesting.totalAmount = vestingAmount;
        vesting.startBlock = block.number;
        vesting.claimedAmount = 0;
        vesting.lastClaimBlock = block.number;

        require(token.transfer(msg.sender, initialReleaseAmount), "Initial token transfer failed");
        //Ensure vestingAmount is transferred to the tokenHolder contract to prevent saftey issues
        require(token.transfer(address(tokenHolder), vestingAmount), "Vesting token transfer failed");

        emit TokensPurchased(msg.sender, tokensAmount, msg.value);
    }

    /**
     * @dev Allows participants to claim their vested tokens
     * @notice Calculates claimable amount and transfers tokens from the TokenHolder contract
     */
    function claim() external {
        Vesting storage vesting = vestings[msg.sender];
        require(vesting.totalAmount > 0, "No vested tokens available");

        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "No tokens to claim at this time");

        vesting.claimedAmount += claimableAmount;
        vesting.lastClaimBlock = block.number;
        tokenHolder.transfer(msg.sender, claimableAmount);

        emit TokensClaimed(msg.sender, claimableAmount);
    }

    /**
     * @dev Calculates the amount of tokens that can be claimed by a user
     * @param user Address of the user
     * @return amount of tokens that can be claimed
     */
    function getClaimableAmount(address user) public view returns (uint256) {
        Vesting storage vesting = vestings[user];
        if (vesting.totalAmount == 0) return 0;

        uint256 elapsedBlocks = block.number - vesting.startBlock;
        uint256 totalVestedAmount = (vesting.totalAmount * elapsedBlocks) / (VESTING_PERIOD * BLOCKS_PER_DAY / 86400);

        if (totalVestedAmount > vesting.totalAmount) {
            totalVestedAmount = vesting.totalAmount;
        }

        if (totalVestedAmount <= vesting.claimedAmount) {
            return 0;
        }

        return totalVestedAmount - vesting.claimedAmount;
    }

    /**
     * @dev Retrieves vesting information for a specific user
     * @param user Address of the user
     * @return totalAmount Total amount of tokens vested
     * @return startBlock Block number when vesting started
     * @return claimedAmount Amount of tokens already claimed
     * @return lastClaimBlock Block number of the last claim
     */
    function getVestingInfo(address user) external view returns (
        uint256 totalAmount,
        uint256 startBlock,
        uint256 claimedAmount,
        uint256 lastClaimBlock
    ) {
        Vesting storage vesting = vestings[user];
        return (vesting.totalAmount, vesting.startBlock, vesting.claimedAmount, vesting.lastClaimBlock);
    }

    /**
     * @dev Retrieves current ICO information
     * @return isActive Whether the ICO is currently active
     * @return startTime Block number when the ICO started
     * @return endTime Block number when the ICO will end
     */
    function getIcoInfo() external view returns (bool isActive, uint256 startTime, uint256 endTime) {
        return (icoActive, icoStartBlock, icoEndBlock);
    }

    /**
     * @dev Retrieves the token price in EUR
     * @return token_price in EUR with 18 decimal places
     */
    function getTokenPriceEur() external pure returns (uint256) {
        return TOKEN_PRICE_EUR;
    }

    /**
     * @dev Checks the current status of the ICO
     * @return icoActive Whether the ICO is currently active
     */
    function icoStatus() external view returns (bool) {
        if(icoActive && block.number > icoEndBlock) {
            return false;
        }
        return icoActive;
    }
}

/**
 * @title TokenHolder
 * @dev Contract to hold vested tokens for ICO participants
 * @notice This contract is controlled by the ICOContract to manage token transfers
 */
contract TokenHolder {
    IERC20 public token;
    address public owner;

    /**
     * @dev Constructor to initialize the TokenHolder contract
     * @param _token Address of the Lethe token contract
     * @param _owner Address of the ICOContract
     */
    constructor(IERC20 _token, address _owner) {
        token = _token;
        owner = _owner;
    }

    /**
     * @dev Transfers tokens to a specified address
     * @param to Address to receive the tokens
     * @param amount Amount of tokens to transfer
     * @notice Can only be called by the ICOContract (owner)
     */
    function transfer(address to, uint256 amount) external {
        require(msg.sender == owner, "Only the owner can transfer tokens");
        require(token.transfer(to, amount), "Token transfer failed");
    }
}
