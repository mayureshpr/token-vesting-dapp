// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Employee.sol";
import "./VestingHelper.sol";
import "hardhat/console.sol";

/**
  *@title Company contract 
  */
contract Company {
    using SafeERC20 for IERC20;
    /**
     *@dev State variable to store on-chain
     */
    address public owner;
    //address[] admins;
    IERC20 public token;
    string public name;
    string public symbol;
    
    // Array of employee wallet address
    address[] public employees;
    // Mapping of employee wallet address to employee contract address
    mapping (address => address) public employeeVesting;

    /**
     * Initialize the company contract with name, symbol, company wallet address as owner
     * and company token contract address
     */
    constructor(string memory companyName, 
        string memory companySymbol, address companyToken) {
        owner = msg.sender;
        name = companyName;
        symbol = companySymbol;
        token = IERC20(companyToken);
    }

    /**
     * Modifier to be used for functions restricted to owner of this 
     * contract
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    function contractAddress() external view returns (address) {
        return address(this);
    }

    /**
     * Create Employee vesting schedule
     */
    function createEmployeeVesting(address employeeWallet, 
        uint64 totalTokensGranted,
        uint64 vestingDuration,
        uint64 startTime,
        uint64 vestingFrequency,
        uint64 lockInPeriod) external onlyOwner {
            // Instantiate Employee contract and store the addess in mapping
            EmployeeVesting employee = new EmployeeVesting(employeeWallet, token, totalTokensGranted,
                vestingDuration, startTime, vestingFrequency, lockInPeriod);
            console.log("employee", employee.contractAddress());
            employeeVesting[employeeWallet] = employee.contractAddress();
            employees.push(employeeWallet);
    }

    /**
     * Called to cancel/suspend the vesting
     */
    function activateEmployeeVesting(address employee) external onlyOwner {
        EmployeeVesting(employeeVesting[employee]).activate();
    }

    /**
     * Get total number of employees
    */
    function getTotalNumEmployees() external onlyOwner view returns(uint) {
        return employees.length;
    }

    /** 
     * returns list of matching status
     *     - Employee vesting info
     * Expensive operation as it doesn't support pagination. 
     * Use getEmployeesPaging() instead
    */
    // function getEmployeeList(uint8 status) external onlyOwner view returns(
    //     address[] memory,
    //     EmployeeVesting.VestingInfo[] memory
    //     ) {
    //     uint totalEmployees = employees.length;
    //     // walk thru the employees and return the list
    //     address[] memory employeeContractAddress = new address[](totalEmployees);
    //     EmployeeVesting.VestingInfo[] memory vestings = new EmployeeVesting.VestingInfo[](totalEmployees);
    //     uint retIndex = 0;
    //     for (uint i=0; i < totalEmployees; i++) {
    //         address employee = employees[i];
    //         EmployeeVesting.VestingInfo memory vestingInfo = employeeVesting[employee].getEmployeeVestingInfo();
    //         if (uint8(vestingInfo.status) == status) {
    //             vestings[retIndex] = vestingInfo;
    //             employeeContractAddress[retIndex] = employeeVesting[employee].contractAddress();
    //             retIndex++;
    //         }
    //     }
    //     return (employeeContractAddress, vestings);
    // }

    /**
      * 
      * returns list 
      *     - Employee contract address
      *     - Employee vesting info
      * Expensive operation as it doesn't support pagination. 
      * Use getEmployeesPaging() instead
      */
    function getEmployeeList() external onlyOwner view returns(
        address[] memory,
        EmployeeVesting.VestingInfo[] memory
        )  {
        uint totalEmployees = employees.length;
        // walk thru the employees and return the list
        address[] memory employeeContractAddress = new address[](totalEmployees);
        EmployeeVesting.VestingInfo[] memory vestings = new EmployeeVesting.VestingInfo[](totalEmployees);
        for (uint i=0; i < employees.length; i++) {
            address employee = employees[i];
            EmployeeVesting employeeVestingContract = EmployeeVesting(employeeVesting[employee]);
            vestings[i] = employeeVestingContract.getEmployeeVestingInfo();
            employeeContractAddress[i] = employeeVestingContract.contractAddress();
        }
        return (employeeContractAddress, vestings);
    }

    /**
      * 
      * Implements pagination for employees
      */
    function getEmployeesPaging(uint offset, uint limit) external onlyOwner view returns(
        address[] memory,
        EmployeeVesting.VestingInfo[] memory
        )  {
        uint totalEmployees = employees.length;
        if (limit == 0) {
            limit = 1;
        }

        if (limit > totalEmployees - offset) {
            limit = totalEmployees - offset;
        }

        // walk thru the employees and return the list
        address[] memory employeeContractAddress = new address[](limit);
        EmployeeVesting.VestingInfo[] memory vestings = new EmployeeVesting.VestingInfo[](limit);
        for (uint i=0; i < limit; i++) {
            address employee = employees[offset + i];
            EmployeeVesting employeeVestingContract = EmployeeVesting(employeeVesting[employee]);
            EmployeeVesting.VestingInfo memory vestingInfo = employeeVestingContract.getEmployeeVestingInfo();
            vestings[i] = vestingInfo;
            employeeContractAddress[i] = employeeVestingContract.contractAddress();
        }
        return (employeeContractAddress, vestings);
    }

    /**
      * Get Employee contract
      * Returns employee vesting info
      */
    function getEmployeeVesting(address employee) external onlyOwner view returns(
        address,
        EmployeeVesting.VestingInfo memory
        ) {
        console.log("getEmployeeVesting", employee, employeeVesting[employee]);
        // console.log("getEmployeeVesting", employeeVesting[employee]);
        EmployeeVesting vesting = EmployeeVesting(employeeVesting[employee]);
        address employeeContract = employeeVesting[employee];
        EmployeeVesting.VestingInfo memory vestingInfo = vesting.getEmployeeVestingInfo();
        console.log('address', employeeContract);
        console.log('vestingInfo', vestingInfo.totalTokensGranted);
        return (employeeContract, vestingInfo);
    }
    
}