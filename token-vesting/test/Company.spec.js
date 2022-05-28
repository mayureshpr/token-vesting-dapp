const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Company Contract", () => {
    let CompanyContract, Erc20Contract;
    let companyContract, erc20Contract;
    let companyAccount;
    let employeeAccount = [];
    // let employeeAccount1, employeeAccount2, employeeAccount3, employeeAccount4, employeeAccount5;

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
    let lockInPeriod = 10;

    beforeEach("Deploy company contract", async () => {
        const accounts = await ethers.getSigners();

        companyAccount = accounts[0];
        employeeAccount[0] = accounts[1];
        employeeAccount[1] = accounts[2];
        employeeAccount[2] = accounts[3];
        employeeAccount[3] = accounts[4];
        employeeAccount[4] = accounts[5];

        // Deploy the ERC20 token
        Erc20Contract = await ethers.getContractFactory("CustomToken");
        erc20Contract = await Erc20Contract.deploy("Test Token", "TST", 1000000);
        await erc20Contract.deployed();

        CompanyContract = await ethers.getContractFactory("Company");
        companyContract = await CompanyContract.deploy(
            "Test Company",
            "TST",
            erc20Contract.address);
        await companyContract.deployed();
    });

    it("should have the correct owner", async () => {
        expect(await companyContract.owner()).to.equal(companyAccount.address);
    });

    it("test company name", async () => {
        expect(await companyContract.name()).to.equal("Test Company");
    });

    it("test company symbol", async () => {
        expect(await companyContract.symbol()).to.equal("TST");
    });

    it("test creating employee contract", async () => {
        await companyContract.createEmployeeVesting(
            employeeAccount[0].address,
            totalTokensGranted,
            vestingDuration,
            startTime,
            vestingFrequency,
            lockInPeriod);
        let {employeeContract, vestingInfo} = await companyContract.getEmployeeVesting(employeeAccount[0].address);
        console.log('contract address', employeeContract);
        console.log('vestingInfo', vestingInfo);
        await expect(employeeContract.status()).to.equal(VestingStatus.NOT_ACTIVE);

        // Test that contract can not be activated before transfering tokens
        await expect(companyContract.activateEmployeeVesting(
            employeeAccount[0].address
        )).to.be.revertedWith("NO_BALANCE");

        // Transfer tokens to employee contract and activate
        await erc20Contract.connect(companyAccount).transfer(employeeContract, totalTokensGranted);
        // activate employee contract
        await companyContract.activateEmployeeVesting(employeeAccount[0].address);
        // let vestingInfo = await employeeContract.getEmployeeVestingInfo();
        expect(await employeeContract.status()).to.equal(VestingStatus.ACTIVE);
    });

    it("Test employee list get", async () => {
        for( let i=0; i<5; i++ ) {
            await companyContract.createEmployeeVesting(
                employeeAccount[i].address,
                totalTokensGranted,
                vestingDuration,
                startTime,
                vestingFrequency,
                lockInPeriod);
        }
        await expect(companyContract.getTotalNumEmployees()).to.equal(5);

        // Test get employee list
        let {employeeAddress, vestingInfo} = await companyContract.getEmployeeList();
        expect(employeeAddress).to.have.lengthOf(5);
        expect(vestingInfo).to.have.lengthOf(5);

        // Test paging
        let {employeeAddress1, vestingInfo1} = await companyContract.getEmployeesPaging(0, 2);
        expect(employeeAddress1).to.have.lengthOf(2);
        expect(vestingInfo1).to.have.lengthOf(2);
    });
});