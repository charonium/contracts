import hre from "hardhat";
import { formatEther, parseEther } from "viem";

async function main() {
  const [deployer] = await hre.viem.getWalletClients();

  // Deploy LetheWhitelist
  console.log("Deploying LetheWhitelist...");
  const letheWhitelist = await hre.viem.deployContract("LetheWhitelist", [deployer.account.address]);
  console.log("LetheWhitelist deployed to:", letheWhitelist.address);

  // Deploy CharonToken
  const charonToken = await hre.viem.deployContract("CharonToken", []);
  console.log("CharonToken deployed to:", charonToken.address);

  // Deploy ICO Contract
  const ICOContract = await hre.viem.deployContract("ICOContract", [charonToken.address]);
  console.log("ICOContract deployed to:", ICOContract.address);

  // Deploy tokenLock contract
  const tokenLock = await hre.viem.deployContract("TokenLock", [charonToken.address]);
  console.log("tokenLock deployed to:", tokenLock.address);

  // Define token allocations
  const allocations = [
    { name: "ICO", amount: parseEther("55200000"), address: ICOContract.address },
    { name: "STRATEGIC_INVEST", amount: parseEther("55200000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "PRIVATE_SALE", amount: parseEther("75900000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "PRESALE", amount: parseEther("48300000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "COMMUNITY_SALE", amount: parseEther("13800000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "ADVISOR_LEGAL", amount: parseEther("27600000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "TEAM", amount: parseEther("69000000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "LIQUIDITY_POOL", amount: parseEther("69000000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "ECOSYSTEM", amount: parseEther("82800000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "COMMUNITY", amount: parseEther("103500000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
    { name: "TREASURY", amount: parseEther("89700000"), address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199" },
  ];

  // Distribute tokens
  for (const allocation of allocations) {
    await charonToken.write.transfer([allocation.address as `0x${string}`, allocation.amount]);
    console.log(`Transferred ${allocation.amount.toString()} tokens to ${allocation.name} (${allocation.address})`);

    // Add each allocation address to the whitelist
    await letheWhitelist.write.addToWhitelist([allocation.address as `0x${string}`]);
    console.log(`Added ${allocation.name} (${allocation.address}) to the whitelist`);
  }

  console.log("All token distributions completed");

  // Verify total distribution
  const totalDistributed = allocations.reduce((sum, allocation) => sum + allocation.amount, BigInt(0));
  console.log(`Total tokens distributed: ${totalDistributed.toString()}`);

  // Verify deployer's remaining balance
  const deployerBalance = await charonToken.read.balanceOf([deployer.account.address]);
  console.log(`Deployer's remaining balance: ${formatEther(BigInt(deployerBalance as bigint))} CHARON`);

  // Additional setup for ICO contract if needed
  // For example, you might want to start the ICO:
  const icoDuration = 30 * 24 * 60 * 60; // 30 days in seconds
  await ICOContract.write.initiate([BigInt(icoDuration)]);
  console.log("ICO started with duration:", icoDuration, "seconds");
  console.log("ICO started");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
