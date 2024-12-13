const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HashiHomes Contract", function () {
    let stakeToken, hashiHomes, deployer, user1, user2;

    beforeEach(async function () {
        [deployer, user1, user2] = await ethers.getSigners();

        console.log("Deployer address:", deployer.address);
        console.log("User1 address:", user1.address);
        console.log("User2 address:", user2.address);

        // Deploy StakeToken
        const StakeToken = await ethers.getContractFactory("StakeToken");
        stakeToken = await StakeToken.deploy(1000000);
        await stakeToken.waitForDeployment();

        const stakeTokenAddress = stakeToken.target || stakeToken.address;
        console.log("StakeToken deployed at:", stakeTokenAddress);
        expect(stakeTokenAddress).to.exist;

        // Deploy HashiHomes
        const HashiHomes = await ethers.getContractFactory("HashiHomes");
        hashiHomes = await HashiHomes.deploy(stakeTokenAddress);
        await hashiHomes.waitForDeployment();

        const hashiHomesAddress = hashiHomes.target || hashiHomes.address;
        console.log("HashiHomes deployed at:", hashiHomesAddress);
        expect(hashiHomesAddress).to.exist;

        // Mint tokens to users
        console.log("Minting tokens to users...");
        await stakeToken.connect(deployer).transfer(user1.address, ethers.parseUnits("1000", 18));
        await stakeToken.connect(deployer).transfer(user2.address, ethers.parseUnits("1000", 18));
        console.log("Tokens minted successfully.");
    });

    it("Should allow users to buy fractional shares of a property", async function () {
        const propertyName = "Luxury Apartment";
        const totalShares = 100;
        const pricePerShare = ethers.parseUnits("10", 18);
        const nftURI = "ipfs://luxury-apartment-metadata";

        console.log("Adding property...");
        // Add property
        await hashiHomes.connect(deployer).addProperty(propertyName, totalShares, pricePerShare, nftURI);

        // Get property ID
        const propertyCount = await hashiHomes.propertyCount();
        const propertyId = parseInt(propertyCount.toString(), 10); // Convert BigNumber to integer
        console.log("Property added with ID:", propertyId);

        // Ensure property ID is valid
        expect(propertyId).to.be.a("number").and.to.be.greaterThan(0);

        // User1 buys shares
        console.log("User1 approving tokens...");
        await stakeToken.connect(user1).approve(hashiHomes.address, ethers.parseUnits("50", 18));
        console.log("User1 buying shares...");
        await hashiHomes.connect(user1).buyShares(propertyId, 5);

        // User2 buys shares
        console.log("User2 approving tokens...");
        await stakeToken.connect(user2).approve(hashiHomes.address, ethers.parseUnits("200", 18));
        console.log("User2 buying shares...");
        await hashiHomes.connect(user2).buyShares(propertyId, 10);

        // Validate ownership
        console.log("Validating ownership...");
        const user1Shares = await hashiHomes.getShares(propertyId, user1.address);
        const user2Shares = await hashiHomes.getShares(propertyId, user2.address);
        console.log("User1 shares:", user1Shares.toString());
        console.log("User2 shares:", user2Shares.toString());
        expect(user1Shares).to.equal(5);
        expect(user2Shares).to.equal(10);

        // Validate property status
        console.log("Validating property status...");
        const updatedProperty = await hashiHomes.properties(propertyId);
        console.log("Updated property status:", updatedProperty);
        expect(updatedProperty.isFullyPurchased).to.be.false;
    });
});
