
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Company.sol";

/**
  *@title Contract that holds all other companies contracts
  * used mostly by the admin of ECO tool.
  */

contract EcoVestingManager is Ownable {
    using SafeERC20 for IERC20;
    //enum CompanyStatus {NOT_CREATED, ACTIVE, DELETE_REQUESTED, DELETED, SUSPENDED}
    /**
      *@dev State variables to be stored on-chain
      */
    //struct CompanyAdminData {
    //    Company companyContract;
    //    CompanyStatus status;
    //}
    address private _admin;
    address[] companies;
    mapping (address => Company) private companyContracts;
    struct CompanyReturnData {
        address companyContractAddress;
        string name;
    }

    constructor() {
        _admin=msg.sender;
    }

    /**
    * Called by company wallet address
    * ?? How can company pass token contract address
    */
    function createCompany(
        string memory name, 
        string memory tokenSymbol, 
        address tokenContract) external {
	    // Check if msg.sender is not already in companies
        //require(
        //    address(companyContracts[msg.sender].owner()) == address(0), 
        //    "Company already has vesting contract"
        //);
	    // Create Company contract by passing msg.sender, name and tokenSymbol to constructor
        Company company = new Company(msg.sender, name, tokenSymbol, tokenContract);
        // store in companies mapping
        //CompanyAdminData memory companyAdminData;
        //companyAdminData.companyContract = company;
        //companyAdminData.status = CompanyStatus.ACTIVE;
        // Check if this copies data from memory to storage
        companyContracts[msg.sender] = company;
        companies.push(msg.sender);
    }

    /**
     * Remove from the companies array
     */
    function removeCompany() private {
        for (uint i=0; i<companies.length; i++) {
            if (companies[i] == msg.sender) {
                companies[i] = companies[companies.length-1];
                companies.pop();
            }
        }
    }

    /**
      * Can be called only by VestingManager admin
      * Company can not delete itself directly
      */
    function deleteCompany() external {
	    // Delete the company contract from companies mapping
        Company company = companyContracts[msg.sender];
        if (company.owner() != address(0)) {
            removeCompany();
        }
    } 

    /**
      * Can be called only by VestingManager admin
      * returns list of
      *     - company name
      *     - company contract address
      */
    // function getCompanyList() external view onlyOwner returns(
    //     CompanyReturnData[] memory
    //     ) {
    //     uint totalCompanies = companies.length;
    //     // Return all companies in mapping 
    //     CompanyReturnData[] memory companyReturnData = new CompanyReturnData[](totalCompanies);
    //     for (uint i=0; i<totalCompanies; i++) {
    //         Company company = companyContracts[companies[i]];
    //         companyReturnData[i] = CompanyReturnData(
    //             company.contractAddress(), 
    //             company.name()
    //         );
    //     }
    //     return companyReturnData;
    // }

    /**
      * 
      * Implements pagination for companies
      */
    function getCompaniesPaging(uint offset, uint limit) external onlyOwner view returns(
        CompanyReturnData[] memory
        )  {
        uint totalCompanies = companies.length;
        if (limit == 0) {
            limit = 1;
        }

        if (limit > totalCompanies - offset) {
            limit = totalCompanies - offset;
        }

        CompanyReturnData[] memory companyReturnData = new CompanyReturnData[](limit);
        for (uint i=0; i < limit; i++) {
            Company company = companyContracts[companies[offset + i]];
            companyReturnData[i] = CompanyReturnData(
                company.contractAddress(), 
                company.name()
            );
        }
        return companyReturnData;
    }

    /**
      * Get Company contract
      * Returns 
      *     - company name
      *     - company contract address
      */
    //function getCompanyContract(address companyContract) external view onlyOwner returns(
    //    CompanyReturnData memory
    //) {
    //}
}