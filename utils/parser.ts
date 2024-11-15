import { ethers } from "hardhat";

export function parseEther(amount: Number) {
  return ethers.parseEther(amount.toString());
}
