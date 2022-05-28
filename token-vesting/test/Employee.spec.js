const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Employee Contract", () => {
    let EmployeeContract, Erc20Contract;
    let employeeContract, erc20Contract;
    let companyAccount;
    let employeeAcoount;

    const VestingStatus = {
        NOT_ACTIVE: 0,
        ACTIVE: 1,
        CANCELLED: 2,
        SUSPENDED: 3,
    };

    let totalTokensGranted = 10000;
    let vestingDuration = 25;
    let startTime = 5;
    let vestingFrequency = 5;
    let lockInPeriod = 5;

    beforeEach("Deploy employee contract", async () => {
        const accounts = await ethers.getSigners();

        companyAccount = accounts[0];
        employeeAcoount = accounts[1];

        // Deploy the ERC20 token
        Erc20Contract = await ethers.getContractFactory("CustomToken");
        erc20Contract = await Erc20Contract.deploy("Test Token", "TST", 1000000);
        // console.log('company address', companyAccount.address);
        // let initialBalance = await erc20Contract.balanceOf(companyAccount.address);
        // console.log('intial balance', initialBalance);
        await erc20Contract.deployed();

        EmployeeContract = await ethers.getContractFactory("EmployeeVesting");
        employeeContract = await EmployeeContract.deploy(
            employeeAcoount.address,
            erc20Contract.address,
            totalTokensGranted,
            vestingDuration,
            startTime,
            vestingFrequency,
            lockInPeriod);
        await employeeContract.deployed();
    });

    it("should have the correct owner", async () => {
        expect(await employeeContract.owner()).to.equal(companyAccount.address);
    });

    it("contract should not be in active when deployed", async () => {
        expect(await employeeContract.status()).to.equal(VestingStatus.NOT_ACTIVE);
    });

    it("Can not activate without transering the tokens", async () => {
        await expect(employeeContract.activate()).to.be.revertedWith("NO_BALANCE");
    });

    it("Activate the vesting", async () => {
        // Transfer vesting tokens to the employee contract
        await erc20Contract.connect(companyAccount).transfer(employeeContract.address, totalTokensGranted);
        // activate employee contract
        await employeeContract.activate();
        // let vestingInfo = await employeeContract.getEmployeeVestingInfo();
        expect(await employeeContract.status()).to.equal(VestingStatus.ACTIVE);
    });

    it("Test the vesting schedule", async () => {
        // Transfer vesting tokens to the employee contract
        await erc20Contract.connect(companyAccount).transfer(employeeContract.address, totalTokensGranted);
        // activate employee contract
        await employeeContract.activate();
        expect(await employeeContract.status()).to.equal(VestingStatus.ACTIVE);
        // Check waiting period before the vesting starts
        setTimeout(async () => {
            let vestingInfo = await employeeContract.getEmployeeVestingInfo();
            expect(vestingInfo.tokenVested.toNumber()).to.equal(0);
        }, startTime-2);

        // Check lock in period
        setTimeout(async () => {
            let vestingInfo = await employeeContract.getEmployeeVestingInfo();
            expect(vestingInfo.tokenVested.toNumber()).to.gt(0);
        }, lockInPeriod-2);
    });

    // it("set vesting status", async () => {
    //     await employeeContract.setVestingStatus(VestingStatus.CANCELLED);
    //     let vestingInfo = await employeeContract.getEmployeeVestingInfo();
    //     let currentBalance = await erc20Contract.balanceOf(companyAccount.address);
    //     console.log('current balance', currentBalance);
    //     expect(vestingInfo.status).to.equal(VestingStatus.CANCELLED);
    // });
});