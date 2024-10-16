// import hre from "hardhat";
// import { parseEther } from "viem";
// import inquirer from "inquirer";

// let charonToken: any;
// let tokenLock: any;
// let icoContract: any;
// let deployer: any;

// async function deployContracts() {
//   console.log("Deploying contracts...");

//   [deployer] = await hre.viem.getWalletClients();

//   charonToken = await hre.viem.deployContract("CharonToken");
//   console.log("CharonToken deployed to:", charonToken.address);

//   tokenLock = await hre.viem.deployContract("TokenLock", [charonToken.address]);
//   console.log("TokenLock deployed to:", tokenLock.address);

//   icoContract = await hre.viem.deployContract("ICOContract", [charonToken.address]);
//   console.log("ICOContract deployed to:", icoContract.address);

//   const approveAmount = parseEther("690000000"); // Increase approval amount for ICO
//   await charonToken.write.approve([tokenLock.address, approveAmount]);
//   await charonToken.write.approve([icoContract.address, approveAmount]);
//   console.log("Approved TokenLock and ICOContract to spend tokens");

//   // Transfer tokens to ICO contract
//   const icoAmount = parseEther("55200000");
//   await charonToken.write.transfer([icoContract.address, icoAmount]);
//   console.log(`Transferred ${icoAmount.toString()} tokens to ICOContract`);
// }

// async function lockTokens() {
//   const { amount, duration } = await inquirer.prompt([
//     {
//       type: "input",
//       name: "amount",
//       message: "Enter amount of tokens to lock:",
//       default: "100",
//     },
//     {
//       type: "input",
//       name: "duration",
//       message: "Enter lock duration in seconds:",
//       default: "3600", // 1 hour
//     },
//   ]);

//   const lockAmount = parseEther(amount);
//   const unlockTime = BigInt(Math.floor(Date.now() / 1000) + Number(duration));

//   await tokenLock.write.lockTokens([lockAmount, unlockTime]);
//   console.log(`Locked ${amount} tokens until ${new Date(Number(unlockTime) * 1000).toLocaleString()}`);
// }

// async function viewLockedTokens() {
//   const [amount, releaseTime] = await tokenLock.read.viewLockedTokens([deployer.account.address]);
//   console.log("Locked tokens:", amount.toString());
//   console.log("Unlock time:", new Date(Number(releaseTime) * 1000).toLocaleString());
// }

// async function withdrawTokens() {
//   try {
//     await tokenLock.write.withdrawTokens();
//     console.log("Tokens withdrawn successfully");
//   } catch (error: any) {
//     console.log("Withdrawing tokens failed:", error.message);
//   }
// }

// async function fastForwardTime() {
//   const { seconds } = await inquirer.prompt([
//     {
//       type: "input",
//       name: "seconds",
//       message: "Enter number of seconds to fast forward:",
//       default: "3600", // 1 hour
//     },
//   ]);

//   await hre.network.provider.send("evm_increaseTime", [Number(seconds)]);
//   await hre.network.provider.send("evm_mine");
//   console.log(`Fast forwarded time by ${seconds} seconds`);
// }

// async function checkBalance() {
//   const balance = await charonToken.read.balanceOf([deployer.account.address]);
//   console.log("Token balance:", balance.toString());
// }

// async function startICO() {
//   const { duration } = await inquirer.prompt([
//     {
//       type: "input",
//       name: "duration",
//       message: "Enter ICO duration in seconds:",
//       default: "86400", // 1 day
//     },
//   ]);

//   await icoContract.write.startICO([BigInt(duration)]);
//   console.log(`ICO started for ${duration} seconds`);
// }

// async function buyICOTokens() {
//   const { amount } = await inquirer.prompt([
//     {
//       type: "input",
//       name: "amount",
//       message: "Enter amount of ETH to spend on ICO tokens:",
//       default: "1",
//     },
//   ]);

//   const ethAmount = parseEther(amount);
//   await icoContract.write.buyTokens({ value: ethAmount });
//   console.log(`Bought ICO tokens with ${amount} ETH`);
// }

// async function claimVestedTokens() {
//   try {
//     await icoContract.write.claimVestedTokens();
//     console.log("Vested tokens claimed successfully");
//   } catch (error: any) {
//     console.log("Claiming vested tokens failed:", error.message);
//   }
// }

// async function viewICOInfo() {
//   const icoRate = await icoContract.read.icoRate();
//   const icoActive = await icoContract.read.icoActive();
//   const icoStartTimestamp = await icoContract.read.icoStartTimestamp();
//   const icoEndTimestamp = await icoContract.read.icoEndTimestamp();

//   console.log("ICO Rate:", icoRate.toString());
//   console.log("ICO Active:", icoActive);
//   console.log("ICO Start Time:", new Date(Number(icoStartTimestamp) * 1000).toLocaleString());
//   console.log("ICO End Time:", new Date(Number(icoEndTimestamp) * 1000).toLocaleString());
// }

// async function viewVestingInfo() {
//   const [totalAmount, startTime, claimedAmount] = await icoContract.read.getVestingInfo([deployer.account.address]);
//   console.log("Total Vested Amount:", totalAmount.toString());
//   console.log("Vesting Start Time:", new Date(Number(startTime) * 1000).toLocaleString());
//   console.log("Claimed Amount:", claimedAmount.toString());

//   const nextReleaseTime = await icoContract.read.getNextReleaseTime([deployer.account.address]);
//   console.log("Next Release Time:", new Date(Number(nextReleaseTime) * 1000).toLocaleString());
// }

// async function main() {
//   await deployContracts();

//   while (true) {
//     const { action } = await inquirer.prompt([
//       {
//         type: "list",
//         name: "action",
//         message: "What would you like to do?",
//         choices: [
//           "Lock Tokens",
//           "View Locked Tokens",
//           "Withdraw Tokens",
//           "Fast Forward Time",
//           "Check Balance",
//           "Start ICO",
//           "Buy ICO Tokens",
//           "Claim Vested Tokens",
//           "View ICO Info",
//           "View Vesting Info",
//           "Exit",
//         ],
//       },
//     ]);

//     switch (action) {
//       case "Lock Tokens":
//         await lockTokens();
//         break;
//       case "View Locked Tokens":
//         await viewLockedTokens();
//         break;
//       case "Withdraw Tokens":
//         await withdrawTokens();
//         break;
//       case "Fast Forward Time":
//         await fastForwardTime();
//         break;
//       case "Check Balance":
//         await checkBalance();
//         break;
//       case "Start ICO":
//         await startICO();
//         break;
//       case "Buy ICO Tokens":
//         await buyICOTokens();
//         break;
//       case "Claim Vested Tokens":
//         await claimVestedTokens();
//         break;
//       case "View ICO Info":
//         await viewICOInfo();
//         break;
//       case "View Vesting Info":
//         await viewVestingInfo();
//         break;
//       case "Exit":
//         return;
//     }
//   }
// }

// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });
