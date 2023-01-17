// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat");

async function main() {
  const Vendor = await ethers.getContractFactory("Vendor");
  const vendor = await upgrades.deployProxy(Vendor, [], {
    initializer: "initialize",
  });
  await vendor.deployed();
  const vendorAddress = vendor.address;

  const CrowdToken = await ethers.getContractFactory("CrowdToken");
  const crowdToken = await upgrades.deployProxy(CrowdToken, [vendorAddress], {
    initializer: "initialize",
  });
  await crowdToken.deployed();
  const crowdTokenAddress = crowdToken.address;

  const setAddress = await vendor.setTokenAddress(crowdTokenAddress);

  const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  const crowdFunding = await upgrades.deployProxy(
    CrowdFunding,
    [crowdTokenAddress],
    {
      initializer: "initialize",
    }
  );
  await crowdFunding.deployed();
  const crowdFundingAddress = crowdFunding.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
