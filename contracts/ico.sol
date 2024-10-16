// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ICOContract is Ownable {
    IERC20 public token;
    uint256 public icoStartBlock;
    uint256 public icoEndBlock;
    bool public icoActive;
    uint256 public constant VESTING_PERIOD = 365 days;
    uint256 private constant BLOCKS_PER_DAY = 43200; // Assuming 2 second block time

    AggregatorV3Interface private ethUsdPriceFeed;
    AggregatorV3Interface private eurUsdPriceFeed;

    // Token price in EUR (0.069 EUR)
    uint256 private constant TOKEN_PRICE_EUR = 69000000000000000;

    struct Vesting {
        uint256 totalAmount;
        uint256 startBlock;
        uint256 claimedAmount;
        uint256 lastClaimBlock;
    }

    mapping(address => Vesting) public vestings;

    event TokensPurchased(address indexed purchaser, uint256 amount, uint256 value);
    event TokensClaimed(address indexed claimant, uint256 amount);
    event IcoStarted(uint256 startTimestamp, uint256 endTimestamp);
    event IcoPaused();
    event IcoResumed();
    event IcoEnded();
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event TokensWithdrawn(address indexed owner, uint256 amount);

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
        ethUsdPriceFeed = AggregatorV3Interface(0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1);
        // eurUsdPriceFeed = AggregatorV3Interface(0xc91D87E81faB8f93699ECf7Ee9B44D11e1D53F0F); //Base Mainnet EUR/USD
    }

    function getEthEurRate() public view returns (uint256) {
        (uint80 ethRoundId, int256 ethUsdPrice, , uint256 ethUpdatedAt, uint80 ethAnsweredInRound) = ethUsdPriceFeed.latestRoundData();
        // (uint80 eurRoundId, int256 eurUsdPrice, , uint256 eurUpdatedAt, uint80 eurAnsweredInRound) = eurUsdPriceFeed.latestRoundData();

        require(ethRoundId == ethAnsweredInRound, "Stale price data");
        require(ethUsdPrice > 0, "Invalid price data");
        require(block.timestamp - ethUpdatedAt <= 3600, "Price data too old");

        // Chainlink 8 decimals
        //return (uint256(ethUsdPrice) * 1e8) / uint256(eurUsdPrice);
        return (uint256(ethUsdPrice) * 1e8) / uint256(109130000);
    }

    function initiate(uint256 durationInBlocks) external onlyOwner {
        require(!icoActive, "ICO is already active");
        icoStartBlock = block.number;
        icoEndBlock = block.number + durationInBlocks;
        icoActive = true;
        emit IcoStarted(icoStartBlock, icoEndBlock);
    }

    function pause() external onlyOwner {
        require(icoActive, "ICO is not active");
        icoActive = false;
        emit IcoPaused();
    }

    function resume() external onlyOwner {
        require(!icoActive, "ICO is already active");
        icoActive = true;
        emit IcoResumed();
    }

    function end() external onlyOwner {
        require(block.number > icoEndBlock, "ICO has not ended yet");
        require(icoActive, "ICO is not active");

        uint256 remainingTokens = token.balanceOf(address(this));
        if (remainingTokens > 0) {
            token.transfer(owner(), remainingTokens);
        }
        icoActive = false;
        emit IcoEnded();
    }

    function contribute() external payable {
        require(icoActive, "ICO is not active");
        require(block.number <= icoEndBlock, "ICO has ended");
        require(vestings[msg.sender].totalAmount == 0, "You have already participated in the ICO");

        uint256 ethEurRate = getEthEurRate();
        // ethEurRate has 8 decimals, msg.value has 18 decimals
        // Multiply first, then divide to maintain precision
        uint256 eurValue = (msg.value * ethEurRate) / 1e18;

        // TOKEN_PRICE_EUR is in 18 decimals, eurValue is in 8 decimals
        // Multiply eurValue by 1e10 to match TOKEN_PRICE_EUR's precision
        uint256 tokensAmount = (eurValue * 1e10 * 1e18) / TOKEN_PRICE_EUR;

        require(tokensAmount <= token.balanceOf(address(this)), "Not enough tokens available");

        uint256 initialReleaseAmount = tokensAmount / 3;
        uint256 vestingAmount = tokensAmount - initialReleaseAmount;

        Vesting storage vesting = vestings[msg.sender];
        vesting.totalAmount = vestingAmount;
        vesting.startBlock = block.number;
        vesting.claimedAmount = 0;
        vesting.lastClaimBlock = block.number;

        require(token.transfer(msg.sender, initialReleaseAmount), "Initial token transfer failed");

        emit TokensPurchased(msg.sender, tokensAmount, msg.value);
    }

    function claim() external {
        Vesting storage vesting = vestings[msg.sender];
        require(vesting.totalAmount > 0, "No vested tokens available");

        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "No tokens to claim at this time");

        vesting.claimedAmount += claimableAmount;
        vesting.lastClaimBlock = block.number;
        require(token.transfer(msg.sender, claimableAmount), "Token transfer failed");

        emit TokensClaimed(msg.sender, claimableAmount);
    }

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

    function getVestingInfo(address user) external view returns (
        uint256 totalAmount,
        uint256 startBlock,
        uint256 claimedAmount,
        uint256 lastClaimBlock
    ) {
        Vesting storage vesting = vestings[user];
        return (vesting.totalAmount, vesting.startBlock, vesting.claimedAmount, vesting.lastClaimBlock);
    }

    function getNextReleaseBlock(address user) external view returns (uint256) {
        Vesting storage vesting = vestings[user];
        if (vesting.totalAmount == 0) return 0;

        uint256 elapsedBlocks = block.number - vesting.startBlock;
        uint256 nextReleaseBlock = vesting.startBlock + ((elapsedBlocks / BLOCKS_PER_DAY + 1) * BLOCKS_PER_DAY);

        uint256 vestingEndBlock = vesting.startBlock + (VESTING_PERIOD * BLOCKS_PER_DAY / 86400);
        return nextReleaseBlock > vestingEndBlock ? 0 : nextReleaseBlock;
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool sent, ) = owner().call{value: balance}("");
        require(sent, "Failed to send Ether");
        emit FundsWithdrawn(owner(), balance);
    }

    function withdrawTokens() external onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to withdraw");
        require(token.transfer(owner(), tokenBalance), "Token transfer failed");
        emit TokensWithdrawn(owner(), tokenBalance);
    }

    function getIcoInfo() external view returns (bool isActive, uint256 startTime, uint256 endTime) {
        return (icoActive, icoStartBlock, icoEndBlock);
    }

    function getTokenPriceEur() external pure returns (uint256) {
        return TOKEN_PRICE_EUR;
    }
}
