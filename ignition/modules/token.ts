import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

const TokenModule = buildModule("TokenModule", (m) => {

  // Deploy LetheWhitelist
  const letheWhitelist = m.contract("LetheWhitelist", [m.getParameter("deployerAddress", m.getAccount(0))]);

  // Deploy Token
  const letheToken = m.contract("Lethe", [letheWhitelist]);

  // Deploy ICO Contract
  const icoContract = m.contract("ICOContract", [letheToken]);

  // Deploy tokenLock contract
  const tokenLock = m.contract("TokenLock", [letheToken]);

  // Define token allocations
  const allocations = [
    { name: "ICO", amount: parseEther("69000000"), address: icoContract },

    { name: "STRATEGIC_INVEST", amount: parseEther("55200000"), address: "0x853D1955482E01b50d687fE6ce222114538BDD9C" },
    { name: "PRIVATE_SALE", amount: parseEther("75900000"), address: "0x853D1955482E01b50d687fE6ce222114538BDD9C" },
    { name: "PRESALE", amount: parseEther("48300000"), address: "0x853D1955482E01b50d687fE6ce222114538BDD9C" },

    { name: "ADVISOR_LEGAL", amount: parseEther("27600000"), address: "0x13b0Cd963e4aCeCaa0cA797Ad4A451c46EB75c0F" },
    { name: "TEAM", amount: parseEther("69000000"), address: "0x13b0Cd963e4aCeCaa0cA797Ad4A451c46EB75c0F" },

    { name: "LIQUIDITY_POOL", amount: parseEther("69000000"), address: "0x764232Fa170D17Ae705C21Da2a43151637D3C284" },

    { name: "ECOSYSTEM", amount: parseEther("82800000"), address: "0xeF60dB4EC3109c35682c2dFd16588D77acB24678" },
    { name: "COMMUNITY", amount: parseEther("103500000"), address: "0xeF60dB4EC3109c35682c2dFd16588D77acB24678" },
    { name: "TREASURY", amount: parseEther("89700000"), address: "0xeF60dB4EC3109c35682c2dFd16588D77acB24678" },
  ];

  // Whitelist addresses
  const whitelistedAddresses = [
    icoContract,
    tokenLock,
    "0x853D1955482E01b50d687fE6ce222114538BDD9C",
    "0x13b0Cd963e4aCeCaa0cA797Ad4A451c46EB75c0F",
    "0x764232Fa170D17Ae705C21Da2a43151637D3C284",
    "0xeF60dB4EC3109c35682c2dFd16588D77acB24678",
  ];

  // Add addresses to whitelist
  whitelistedAddresses.forEach((address, index) => {
    m.call(letheWhitelist, "addToWhitelist", [address], {
      id: `whitelist_${index}`
    });
  });


  // Distribute tokens
  allocations.forEach((allocation, index) => {
    const transferFuture = m.call(letheToken, "transfer", [
      allocation.address,
      allocation.amount
    ], {
      id: `transfer_${allocation.name}_${index}`
    });
    console.log(`Transferred ${allocation.amount.toString()} tokens to ${allocation.name}`);
  });

  // Log total distribution
  const totalDistributed = allocations.reduce((sum, allocation) => sum + allocation.amount, BigInt(0));
  console.log(`Total tokens distributed: ${totalDistributed.toString()}`);

  // Get deployer's remaining balance
  const deployerAddress = m.getParameter("deployerAddress", m.getAccount(0));
  const deployerBalance = m.staticCall(letheToken, "balanceOf", [deployerAddress]);
  console.log(`Deployer's remaining balance: ${deployerBalance}`);

  // Additional setup for ICO contract if needed
  // For example, you might want to start the ICO:
  // const icoDuration = m.getParameter("icoDuration", 30 * 24 * 60 * 60); // 30 days in seconds
  // m.call(icoContract, "startICO", [icoDuration]);
  // console.log("ICO started");

  return { letheWhitelist, letheToken, icoContract, tokenLock };

});

export default TokenModule;
