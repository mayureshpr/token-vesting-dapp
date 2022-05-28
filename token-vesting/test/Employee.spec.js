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
    let lockInPeriod = 10;

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

        // Activate the contract
        // Transfer vesting tokens to the employee contract
        await erc20Contract.connect(companyAccount).transfer(employeeContract.address, totalTokensGranted);
        // activate employee contract
        await employeeContract.activate();
        expect(await employeeContract.status()).to.equal(VestingStatus.ACTIVE);

        // Check waiting period before the vesting starts
        // await new Promise(r => setTimeout(r, startTime-2));
        await ethers.provider.send("evm_increaseTime", [startTime - 2]);
        await ethers.provider.send("evm_mine");
        let vestingInfo = await employeeContract.getEmployeeVestingInfo();
        expect(vestingInfo.tokensVested.toNumber()).to.equal(0);

        // Check lock in period and transfer
        // await new Promise(r => setTimeout(r, lockInPeriod-2));
        await ethers.provider.send("evm_increaseTime", [lockInPeriod-2]);
        await ethers.provider.send("evm_mine");
        vestingInfo = await employeeContract.getEmployeeVestingInfo();
        expect(vestingInfo.tokensVested.toNumber()).to.gt(0);
        await expect(
            employeeContract.transferTokensToEmployeeWallet()
        ).to.be.revertedWith("LOCKINPERIOD_NOT_OVER");

        // Test transfer after lockin period
        // transfer tokens to the employee account
        await ethers.provider.send("evm_increaseTime", [5]);
        await ethers.provider.send("evm_mine");
        vestingInfo = await employeeContract.getEmployeeVestingInfo();
        await employeeContract.transferTokensToEmployeeWallet();
        let balance = await erc20Contract.balanceOf(employeeAcoount.address);
        expect(balance.toNumber()).to.gte(vestingInfo.tokensVested.toNumber());

        // Test vesting done
        await ethers.provider.send("evm_increaseTime", [vestingDuration - lockInPeriod]);
        await ethers.provider.send("evm_mine");
        vestingInfo = await employeeContract.getEmployeeVestingInfo();
        await employeeContract.transferTokensToEmployeeWallet();
        balance = await erc20Contract.balanceOf(employeeAcoount.address);
        expect(balance.toNumber()).to.equal(totalTokensGranted);
    });
    // describe("Test the vesting schedule", () => {

    //     it("activate contract", async () => {
    //         // Transfer vesting tokens to the employee contract
    //         await erc20Contract.connect(companyAccount).transfer(employeeContract.address, totalTokensGranted);
    //         // activate employee contract
    //         await employeeContract.activate();
    //         expect(await employeeContract.status()).to.equal(VestingStatus.ACTIVE);
    //     });

    //     it('wait to test start time', async () => {        
    //         await ethers.provider.send("evm_increaseTime", [3]);
    //     });

    //     it("test start time period", async () => {
    //         // Check waiting period before the vesting starts
    //         // await new Promise(r => setTimeout(r, startTime-2));
    //         // await ethers.provider.send("evm_increaseTime", [3]);
    //         let vestingInfo = await employeeContract.getEmployeeVestingInfo();
    //         expect(vestingInfo.tokensVested.toNumber()).to.equal(0);
    //     });

    //     it("Test lock in period", async () => {
    //         // await new Promise(r => setTimeout(r, lockInPeriod-2));
    //         await ethers.provider.send("evm_increaseTime", [10]);
    //         let vestingInfo = await employeeContract.getEmployeeVestingInfo();
    //         // console.log(vestingInfo);
    //         expect(vestingInfo.tokensVested.toNumber()).to.gt(0);
    //     });

    //     it("Test transfer tokens", async () => {
    //         // transfer tokens to the employee account
    //         await employeeContract.transferTokensToEmployeeWallet();
    //         let balance = await erc20Contract.balanceOf(employeeAcoount.address);
    //         console.log(balance.toNumber());
    //         let vestingInfo = await employeeContract.getEmployeeVestingInfo();
    //         expect(balance.toNumber()).to.gte(vestingInfo.tokensVested.toNumber());
    //     });
    // });

    // it("set vesting status", async () => {
    //     await employeeContract.setVestingStatus(VestingStatus.CANCELLED);
    //     let vestingInfo = await employeeContract.getEmployeeVestingInfo();
    //     let currentBalance = await erc20Contract.balanceOf(companyAccount.address);
    //     console.log('current balance', currentBalance);
    //     expect(vestingInfo.status).to.equal(VestingStatus.CANCELLED);
    // });
});