const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Employee Contract", () => {
    let EmployeeContract, Erc20Contract;
    let employeeContract, erc20Contract;
    let companyAccount;
    let employeeAcoount;

    const VestingStatus = {
        ACTIVE: 0,
        CANCELLED: 1,
        SUSPENDED: 2,
    };

    beforeEach("Deploy employee contract", async () => {
        const accounts = await ethers.getSigners();

        companyAccount = accounts[0];
        employeeAcoount = accounts[1];

        // Deploy the ERC20 token
        Erc20Contract = await ethers.getContractFactory("CustomToken");
        erc20Contract = await Erc20Contract.deploy("Test Token", "TST", 1000000);
        await erc20Contract.deployed();

        EmployeeContract = await ethers.getContractFactory("EmployeeVesting");
        employeeContract = await EmployeeContract.deploy(
            employeeAcoount.address,
            erc20Contract.address,
            10000,
            126144000,
            31600,
            100000,
            31536000,
            VestingStatus.ACTIVE);
        await employeeContract.deployed();
    });

    it("set vesting status", async () => {
        await employeeContract.setVestingStatus(VestingStatus.CANCELLED);
        let vestingInfo = await employeeContract.getEmployeeVestingInfo();
        expect(vestingInfo.status).to.equal(VestingStatus.CANCELLED);
    });
});