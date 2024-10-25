import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther, formatEther } from "viem";

const TokenModule = buildModule("TokenModule", (m) => {
  // STEP 1: Setup initial variables and deployer
  const deployer = m.getAccount(0);
  console.log("Deployer address:", deployer);

  // STEP 2: Deploy main token contract
  const letheToken = m.contract("Lethe", []);
  console.log("Lethe token deployment initiated");

  // STEP 3: Verify initial token supply
  m.call(letheToken, "balanceOf", [deployer], {
    id: "verify_initial_supply"
  });

  // STEP 4: Deploy supporting contracts
  const icoContract = m.contract("ICOContract", [letheToken]);
  const vestingContract = m.contract("TokenVesting", [letheToken]);

  // STEP 5: Setup vesting schedule timing
  const NOW = Math.floor(Date.now() / 1000) + (10); // 10 seconds buffer

  // STEP 6: Define vesting configurations
  const vestingConfigs = [
    {
      name: "TEAM_VESTING",
      beneficiary: "0x13b0Cd963e4aCeCaa0cA797Ad4A451c46EB75c0F",
      amount: parseEther("69000000"),
      start: NOW,
      cliff: 365 * 24 * 60 * 60, // 12 months cliff
      duration: 2 * 365 * 24 * 60 * 60, // 24 months vesting
      slicePeriodSeconds: 1, // claimable every 1 second
      revocable: true
    },
    {
      name: "ADVISOR_LEGAL_VESTING",
      beneficiary: "0x13b0Cd963e4aCeCaa0cA797Ad4A451c46EB75c0F",
      amount: parseEther("27600000"),
      start: NOW,
      cliff: 365 * 24 * 60 * 60, // 12 months cliff
      duration: 2 * 365 * 24 * 60 * 60, // 24 months vesting
      slicePeriodSeconds: 1, // claimable every 1 second
      revocable: true
    },
    {
      name: "STRATEGIC_VESTING",
      beneficiary: "0x853D1955482E01b50d687fE6ce222114538BDD9C",
      amount: parseEther("55200000"),
      start: NOW,
      cliff: 8 * 30 * 24 * 60 * 60, // 8 months cliff
      duration: 16 * 30 * 24 * 60 * 60, // 16 months vesting
      slicePeriodSeconds: 1, // claimable every 1 second
      revocable: true
    },
    {
      name: "LIQUIDITY_POOL_VESTING",
      beneficiary: "0x764232Fa170D17Ae705C21Da2a43151637D3C284",
      amount: parseEther("69000000"),
      start: NOW,
      cliff: 0,
      duration: 18 * 30 * 24 * 60 * 60, // 18 months vesting
      slicePeriodSeconds: 1, // claimable every 1 second
      revocable: true
    },
    {
      name: "ECOSYSTEM_VESTING",
      beneficiary: "0xeF60dB4EC3109c35682c2dFd16588D77acB24678",
      amount: parseEther("82800000"),
      start: NOW,
      cliff: 0,
      duration: 36 * 30 * 24 * 60 * 60, // 36 months vesting
      slicePeriodSeconds: 1, // claimable every 1 second
      revocable: true
    },
    {
      name: "TREASURY_VESTING",
      beneficiary: "0xeF60dB4EC3109c35682c2dFd16588D77acB24678",
      amount: parseEther("89700000"),
      start: NOW,
      cliff: 0,
      duration: 36 * 30 * 24 * 60 * 60, // 36 months vesting
      slicePeriodSeconds: 1, // claimable every 1 second
      revocable: true
    },
  ];

  // STEP 7: Define direct allocation configurations
  const directAllocations = [
    { name: "ICO", amount: parseEther("69000000"), address: icoContract },
    { name: "PRIVATE_SALE", amount: parseEther("75900000"), address: "0x853D1955482E01b50d687fE6ce222114538BDD9C" },
    { name: "PRESALE", amount: parseEther("48300000"), address: "0x853D1955482E01b50d687fE6ce222114538BDD9C" },
    { name: "COMMUNITY", amount: parseEther("103500000"), address: "0xeF60dB4EC3109c35682c2dFd16588D77acB24678" },
  ];

  // STEP 8: Define whitelist addresses
  const whitelistedAddresses = [
    icoContract,
    vestingContract,
    "0x853D1955482E01b50d687fE6ce222114538BDD9C", // Strategic/Private/Presale
    "0x13b0Cd963e4aCeCaa0cA797Ad4A451c46EB75c0F", // Team/Advisory
    "0x764232Fa170D17Ae705C21Da2a43151637D3C284", // Liquidity Pool
    "0xeF60dB4EC3109c35682c2dFd16588D77acB24678", // Ecosystem/Treasury/Community
  ];

  // STEP 9: Deploy all vesting contracts first
  console.log("Setting up vesting schedules...");

  // Add vesting contract to whitelist first
  m.call(letheToken, "addToWhitelist", [vestingContract], {
    id: "whitelist_vesting_contract"
  });

  // Handle each vesting config
  vestingConfigs.forEach((config, index) => {
    console.log(`Setting up vesting for ${config.name}`);

    // First transfer tokens to vesting contract
    const transferCall = m.call(letheToken, "transfer", [vestingContract, config.amount], {
      id: `transfer_to_vesting_${config.name}`
    });

    // Create vesting schedule AFTER the transfer (note the dependency)
    m.call(vestingContract, "createVestingSchedule", [
      config.beneficiary,
      BigInt(config.start),
      BigInt(config.cliff),
      BigInt(config.duration),
      BigInt(config.slicePeriodSeconds),
      config.revocable,
      config.amount
    ], {
      id: `create_vesting_schedule_${config.name}`,
      after: [transferCall] // This ensures the transfer happens first
    });

    // Verify the transfer
    m.call(letheToken, "balanceOf", [vestingContract], {
      id: `verify_vesting_balance_${config.name}`
    });
  });

  // STEP 10: Whitelist setup
  // First whitelist deployer (is already whitelisted in the token contract constructor)
  console.log("Setting up whitelist...");
  m.call(letheToken, "addToWhitelist", [deployer], {
    id: "whitelist_deployer"
  });

  // Then whitelist all addresses
  whitelistedAddresses.forEach((address, index) => {
    m.call(letheToken, "addToWhitelist", [address], {
      id: `whitelist_address_${index}`
    });
  });

  // STEP 13: Handle direct transfers
  console.log("Processing direct transfers...");
  directAllocations.forEach((allocation, index) => {
    // Check balance before transfer
    m.call(letheToken, "balanceOf", [deployer], {
      id: `pre_direct_balance_${index}`
    });

    // Transfer tokens
    console.log(`Transferring ${formatEther(allocation.amount)} LETHE to ${allocation.name}`);
    m.call(letheToken, "transfer", [
      allocation.address,
      allocation.amount
    ], {
      id: `direct_transfer_${index}`
    });
  });

  // STEP 14: Final verification
  console.log("Performing final verification...");
  const totalVested = vestingConfigs.reduce((sum, config) => sum + config.amount, BigInt(0));
  const totalDirect = directAllocations.reduce((sum, allocation) => sum + allocation.amount, BigInt(0));
  const totalDistributed = totalVested + totalDirect;
  const expectedTotal = parseEther("690000000");

  console.log(`Total vested: ${formatEther(totalVested)} LETHE`);
  console.log(`Total direct: ${formatEther(totalDirect)} LETHE`);
  console.log(`Total distributed: ${formatEther(totalDistributed)} LETHE`);

  if (totalDistributed !== expectedTotal) {
    throw new Error(`Distribution mismatch: ${formatEther(totalDistributed)} != ${formatEther(expectedTotal)}`);
  }

  // LAST STEP: Return deployed contracts
  return {
    letheToken,
    icoContract,
    vestingContract,
  };
});

export default TokenModule;
