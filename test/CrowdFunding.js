const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

let contract, vendorContract, tokenAddress, tokenContract, vendorAddress;

describe("VendorContract", function () {
  it("should deploy the vendor contract to the mumbai testnet", async function () {
    const Vendor = await ethers.getContractFactory("Vendor");
    const vendor = await upgrades.deployProxy(Vendor, [], {
      initializer: "initialize",
    });
    vendorContract = await vendor.deployed();
    vendorAddress = vendorContract.address;
  });
});

describe("CrowdTokenContract", function () {
  it("should deploy the crowd token contract to the mumbai testnet", async function () {
    const CrowdToken = await ethers.getContractFactory("CrowdToken");
    const crowdToken = await upgrades.deployProxy(CrowdToken, [vendorAddress], {
      initializer: "initialize",
    });
    tokenContract = await crowdToken.deployed();
    tokenAddress = tokenContract.address;
  });
});

describe("SetTokenAddress", function () {
  it("should set the token address in the vendor contract", async function () {
    const setAddress = await vendorContract.setTokenAddress(tokenAddress);
    const setEvent = await setAddress.wait();
    expect(setEvent.status).to.equal(1);
  });
});

describe("CrowdFundingContract", function () {
  it("should deploy the crowdfunding contract to the mumbai testnet", async function () {
    const CrowdFundingContract = await ethers.getContractFactory(
      "CrowdFunding"
    );
    const crowdFundingContract = await CrowdFundingContract.deploy();
    contract = await crowdFundingContract.deployed();
    console.log(
      "CrowdFundingContract deployed to:",
      crowdFundingContract.address
    );
  });
});

describe("Buy Tokens", function () {
  it("should buy tokens", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const buyTokens = await vendorContract.connect(addr2).buyToken({
      value: ethers.utils.parseEther("10.0"),
    });
    const buyEvent = await buyTokens.wait();
    expect(buyEvent.status).to.equal(1);
  });
});
describe("Approve Token", function () {
  it("should approve tokens", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const approveTokens = await tokenContract
      .connect(addr2)
      .approve(contract.address, 2000);
    const approveEvent = await approveTokens.wait();
    expect(approveEvent.status).to.equal(1);
  });
});
describe("Create Campaign", function () {
  it("should create a campaign", async function () {
    const [owner, addr1] = await ethers.getSigners();
    const campaign = await contract
      .connect(addr1)
      .createAppeal(
        "Test Campaign",
        "An Appeal for donation to our cause",
        1000,
        600
      );
    const campaignId = await campaign.wait();
    expect(campaignId.status).to.equal(1);
  });

  it("should not create campaign with an empty title", async function () {
    const [owner, addr1] = await ethers.getSigners();
    await expect(
      contract
        .connect(addr1)
        .createAppeal("", "An Appeal for donation", 1000, 600)
    ).to.be.revertedWith("Name is required");
  });
  it("should not create campaign with an empty description", async function () {
    const [owner, addr1] = await ethers.getSigners();
    await expect(
      contract.connect(addr1).createAppeal("Test Campaign", "", 1000, 600)
    ).to.be.revertedWith("Description is required");
  });
  it("should not create campaign with a target amount of 0", async function () {
    const [owner, addr1] = await ethers.getSigners();
    await expect(
      contract
        .connect(addr1)
        .createAppeal("Test Campaign", "An Appeal for donation", 0, 600)
    ).to.be.revertedWith("Target amount is required");
  });
  it("should not create campaign with a deadline of 0", async function () {
    const [owner, addr1] = await ethers.getSigners();
    await expect(
      contract
        .connect(addr1)
        .createAppeal("Test Campaign", "An Appeal for donation", 1000, 0)
    ).to.be.revertedWith("Deadline is required");
  });
});

describe("Fund Campaign", function () {


  it("should fund a campaign", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const campaign = await contract.connect(addr2).donate(1, 1000);

    const campaignId = await campaign.wait();

    console.log("campaignId", campaignId);
    expect(contract.appeals[1].amountRaised).to.equal(1000);
  });
  it("should not fund a campaign that does not exist", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await expect(contract.connect(addr2).donate(2, 1000)).to.be.revertedWith(
      "Invalid appeal id"
    );
  });
  it("should not fund a campaign with an amount of 0", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await expect(contract.connect(addr2).donate(1, 0)).to.be.revertedWith(
      "Amount is required"
    );
  });

  it("should not allow beneficiary donate", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await expect(contract.connect(addr1).donate(1, 1000)).to.be.revertedWith(
      "Beneficiary cannot donate"
    );
  });
});

describe("endCampaign", function () {
  it("should not end campaign before deadline", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await expect(contract.connect(addr1).endAppeal(1)).to.be.revertedWith(
      "Deadline has not passed"
    );
  });
  it("should end a campaign", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await time.increase(3600);
    const campaign = await contract.connect(addr1).endAppeal(1);
    const campaignId = await campaign.wait();
    expect(campaignId.status).to.equal(1);
  });

  it("should mark appeal as ended", async function () {
    const appeal = await contract.appeals(1);
    expect(appeal.completed).to.equal(true);
  });

  it("should transfer raised amount to beneficiary", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const balance = await tokenContract.balanceOf(addr1.address);
    expect(balance).to.greaterThanOrEqual(1000);
  });

  it("should refund donors if target amount is not reached", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const campaign = await contract
      .connect(addr1)
      .createAppeal(
        "Test Campaign",
        "An Appeal for donation to our cause",
        1000,
        600
      );
    const campaignId = await campaign.wait();
    const appeal = await contract.appeals(2);
    expect(appeal.completed).to.equal(false);
    const balance = await tokenContract.balanceOf(addr1.address);
    expect(balance).to.equal(0);
  });
});

describe("getAppeals", function () {
  it("should return all appeals", async function () {
    const appeals = await contract.getAppeals();
    expect(appeals.length).to.equal(2);
  });
});

describe("getDonors", function () {
  it("should return all donors", async function () {
    const donors = await contract.getDonors();
    expect(donors.length).to.greaterThanOrEqual(1);
  });
});
