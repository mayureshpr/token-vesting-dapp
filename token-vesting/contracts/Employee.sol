// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VestingHelper.sol";

/**
  *@title Employee vesting contract 
  */
contract EmployeeVesting is VestingHelper {
    using SafeERC20 for IERC20;
    enum VestingStatus {ACTIVE, CANCELLED, SUSPENDED}
    /**
     *@dev State variable to store on-chain
     */
    address public owner;
    IERC20 private _token;
    uint public contractCreateTime;    // block.timestamp at the time of contract creation
    address public employeeWallet;
    uint64 public totalTokensGranted;
    uint64 public tokensTransferred;
    uint64 public vestingDuration; // in seconds
    uint64 public startTime; // delta in secoonds from contract creation
    uint64 public vestingFrequency; // in seconds
    uint64 public lockInPeriod; // in seconds
    VestingStatus public status; // vestingStatus enum

    // This structure is just for returning the information and doesn't represent 
    // actual storage on the block
    struct VestingInfo {
        uint contractCreateTime;    // block.timestamp at the time of contract creation
        address employeeWallet;
        uint64 totalTokensGranted;
        uint64 tokensTransferred;
        uint64 tokensVested;
        uint64 vestingDuration; // in seconds
        uint64 startTime; // delta in secoonds from contract creation
        uint64 vestingFrequency; // in seconds
        uint64 lockInPeriod; // in seconds
        VestingStatus status; // vestingStatus enum
    }

    // Events emitted by this contract
    event VestingCreated(address indexed employeeWallet, 
        uint64 totalTokensGranted, 
        uint64 vestingDuration, 
        uint64 startTime, 
        uint64 vestingFrequency, 
        uint64 lockInPeriod, 
        VestingStatus status);
    event VestingCancelled(address indexed employeeWallet);
    event VestedTokensTransferred(address indexed employeeWallet, uint64 tokensTransferred);

    
    constructor(address _employeeWallet, 
        IERC20 token,
        uint64 _totalTokensGranted,
        uint64 _vestingDuration,
        uint64 _startTime,
        uint64 _vestingFrequency,
        uint64 _lockInPeriod,
        VestingStatus _status) VestingHelper() {
            require(token.balanceOf(msg.sender) >= totalTokensGranted, "Insufficient balance");
            owner = msg.sender;
            _token = token;
            contractCreateTime = block.timestamp;
            employeeWallet = _employeeWallet;
            totalTokensGranted = _totalTokensGranted;
            vestingDuration = _vestingDuration;
            startTime = _startTime;
            vestingFrequency = _vestingFrequency;
            lockInPeriod = _lockInPeriod;
            status = _status;
            emit VestingCreated(employeeWallet, 
                totalTokensGranted, 
                vestingDuration, 
                startTime, 
                vestingFrequency, 
                lockInPeriod, 
                status);
    }

    /**
     * Modifier to be used for functions restricted to owner of this 
     * contract
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner of this contract can call this function");
        _;
    }

    /**
     * Set vesting status of the contract
     */
    function setVestingStatus(VestingStatus _status) external onlyOwner callOnlyWhenActive {
        status = _status;
    }

    /**
     * Set vesting frequency of the contract
     */
    // function setVestingFrequency(uint64 vestingFrequency) external onlyOwner callOnlyWhenActive {
    //     vestingFrequency = vestingFrequency;
    // }

    /**
     * Set vesting start time of the contract
     */
    // function setVestingStartTime(uint64 startTime) external onlyOwner callOnlyWhenActive {
    //     startTime = startTime;
    // }
    
    /**
     * Set vesting duration of the contract
     */
    // function setVestingDuration(uint64 vestingDuration) external onlyOwner callOnlyWhenActive {
    //     vestingDuration = vestingDuration;
    // }

    function getTokensVested() private view returns(uint256) {
        // Calculate the tokens vested per vesting frequency
        uint64 vestingCycles = vestingDuration / vestingFrequency;
        uint64 tokensVestedPerCycle = totalTokensGranted / vestingCycles;
        // Calculate the tokens vested till now
        uint256 tokensVested;
        if (contractCreateTime + startTime < block.timestamp) {
            tokensVested = ((
                block.timestamp - contractCreateTime - startTime
                ) / vestingFrequency) * tokensVestedPerCycle;
        } else {
            tokensVested = 0;
        }
        return tokensVested;
    }

    /**
      * Get Employee contract
      * Can be called only by Employee OR the owner of the contract
      * Returns employee vesting info
      */
    function getEmployeeVestingInfo() external view returns(VestingInfo memory) {
        // Check if employee OR owner is calling it
        require(
            (msg.sender == employeeWallet || msg.sender == owner),
            "Only Employee who owns this contract OR company can call it"
        );
        uint256 tokensVested;
        if (status == VestingStatus.ACTIVE) {
            tokensVested = getTokensVested();
        } else {
            tokensVested = 0;
        }

        VestingInfo memory vestingInfo = VestingInfo(
            contractCreateTime,
            employeeWallet,
            totalTokensGranted,
            tokensTransferred,
            uint64(tokensVested),
            vestingDuration,
            startTime,
            vestingFrequency,
            lockInPeriod,
            status
        );
        return vestingInfo;
    }

    /*
     * Transfer tokens to employee wallet
     * Can be called only by Employee OR the owner of the contract
     */
    function transferTokensToEmployeeWallet() external {
        // Check if employee OR owner is calling it
        require(
            (msg.sender == employeeWallet || msg.sender == owner),
            "Only Employee who owns this contract OR company can call it"
        );
        require(status == VestingStatus.ACTIVE, "Vesting is not active");

        uint256 tokensVested = getTokensVested();
        if (tokensVested > tokensTransferred) {
            uint256 tokensToTransfer = tokensVested - tokensTransferred;
            _token.transfer(employeeWallet, tokensToTransfer);
            tokensTransferred = uint64(tokensVested);
            emit VestedTokensTransferred(employeeWallet, uint64(tokensToTransfer));
        }
    }
}