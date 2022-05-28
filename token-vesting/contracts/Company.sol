// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Employee.sol";
import "./VestingHelper.sol";

/**
  *@title Company contract 
  */
contract Company is VestingHelper {
    using SafeERC20 for IERC20;
    /**
     *@dev State variable to store on-chain
     */
    address private _owner;
    //address[] admins;
    IERC20 private _token;
    string private _name;
    string private _symbol;
    
    address[] public employees;
    mapping (address => EmployeeVesting) public employeeVesting;

    /**
     * Initialize the company contract with name, symbol, company wallet address as owner
     * and company token contract address
     */
    constructor(address companyOwner, string memory companyName, 
        string memory companySymbol, address token) VestingHelper() {
        _owner = companyOwner;
        _name = companyName;
        _symbol = companySymbol;
        _token = IERC20(token);
    }

    /**
     * Modifier to be used for functions restricted to owner of this 
     * contract
     */
    modifier restrictedToCompany() {
        require(msg.sender == _owner, "Only company owner can call this function");
        _;
    }

    function owner() external view returns(address) {
        return _owner;
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    /**
     * Create Employee vesting schedule
     */
    function createEmployeeVesting(address employeeWallet, 
        uint64 totalTokensGranted,
        uint64 vestingDuration,
        uint64 startTime,
        uint64 vestingFrequency,
        uint64 lockInPeriod) external restrictedToCompany callOnlyWhenActive {
            // Instantiate Employee contract and store the addess in mapping
            EmployeeVesting employee = new EmployeeVesting(employeeWallet, _token, totalTokensGranted,
                vestingDuration, startTime, vestingFrequency, lockInPeriod);
            employeeVesting[employeeWallet] = employee;
            employees.push(employeeWallet);
    }

    /**
     * Called to cancel/suspend the vesting
     */
    function activateEmployeeVesting(address employee) external restrictedToCompany callOnlyWhenActive {
        employeeVesting[employee].activate();
    }

    /**
     * Get total number of employees
    */
    function getTotalNumEmployees() external restrictedToCompany callOnlyWhenActive view returns(uint) {
        return employees.length;
    }

    /** 
     * returns list of matching status
     *     - Employee vesting info
     * Expensive operation as it doesn't support pagination. 
     * Use getEmployeesPaging() instead
    */
    function getEmployeeList(uint8 status) external restrictedToCompany callOnlyWhenActive view returns(
        address[] memory,
        EmployeeVesting.VestingInfo[] memory
        ) {
        uint totalEmployees = employees.length;
        // walk thru the employees and return the list
        address[] memory employeeContractAddress = new address[](totalEmployees);
        EmployeeVesting.VestingInfo[] memory vestings = new EmployeeVesting.VestingInfo[](totalEmployees);
        uint retIndex = 0;
        for (uint i=0; i < totalEmployees; i++) {
            address employee = employees[i];
            EmployeeVesting.VestingInfo memory vestingInfo = employeeVesting[employee].getEmployeeVestingInfo();
            if (uint8(vestingInfo.status) == status) {
                vestings[retIndex] = vestingInfo;
                employeeContractAddress[retIndex] = employeeVesting[employee].contractAddress();
                retIndex++;
            }
        }
        return (employeeContractAddress, vestings);
    }

    /**
      * 
      * returns list 
      *     - Employee contract address
      *     - Employee vesting info
      * Expensive operation as it doesn't support pagination. 
      * Use getEmployeesPaging() instead
      */
    function getEmployeeList() external restrictedToCompany callOnlyWhenActive view returns(
        address[] memory,
        EmployeeVesting.VestingInfo[] memory
        )  {
        uint totalEmployees = employees.length;
        // walk thru the employees and return the list
        address[] memory employeeContractAddress = new address[](totalEmployees);
        EmployeeVesting.VestingInfo[] memory vestings = new EmployeeVesting.VestingInfo[](totalEmployees);
        for (uint i=0; i < employees.length; i++) {
            address employee = employees[i];
            EmployeeVesting employeeVestingContract = employeeVesting[employee];
            vestings[i] = employeeVestingContract.getEmployeeVestingInfo();
            employeeContractAddress[i] = employeeVestingContract.contractAddress();
        }
        return (employeeContractAddress, vestings);
    }

    /**
      * 
      * Implements pagination for employees
      */
    function getEmployeesPaging(uint offset, uint limit) external restrictedToCompany callOnlyWhenActive view returns(
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
            EmployeeVesting employeeVestingContract = employeeVesting[employee];
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
    function getEmployeeVesting(address employee) external restrictedToCompany callOnlyWhenActive view returns(
        address,
        EmployeeVesting.VestingInfo memory
        )  {
        return (
            employeeVesting[employee].contractAddress(),
            employeeVesting[employee].getEmployeeVestingInfo()
        );
    }
    
}