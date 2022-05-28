// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VestingHelper.sol";
import "hardhat/console.sol";

/**
 *@title Employee vesting contract
 */
contract EmployeeVesting {
    using SafeERC20 for IERC20;
    enum VestingStatus {
        NOT_ACTIVE,
        ACTIVE,
        CANCELLED,
        SUSPENDED
    }
    /**
     *@dev State variable to store on-chain
     */
    address public owner;
    IERC20 private _token;
    uint public contractCreateTime; // block.timestamp at the time of contract creation
    address public employeeWallet;
    uint256 public totalTokensGranted;
    uint256 public tokensTransferred;
    uint64 public vestingDuration; // in seconds
    uint64 public startTime; // delta in secoonds from contract creation
    uint64 public vestingFrequency; // in seconds
    uint64 public lockInPeriod; // in seconds
    VestingStatus public status; // vestingStatus enum

    // This structure is just for returning the information and doesn't represent
    // actual storage on the block
    struct VestingInfo {
        uint contractCreateTime; // block.timestamp at the time of contract creation
        address employeeWallet;
        uint256 totalTokensGranted;
        uint256 tokensTransferred;
        uint256 tokensVested;
        uint64 vestingDuration; // in seconds
        uint64 startTime; // delta in secoonds from contract creation
        uint64 vestingFrequency; // in seconds
        uint64 lockInPeriod; // in seconds
        VestingStatus status; // vestingStatus enum
    }

    // Events emitted by this contract
    event VestingCreated(
        address indexed employeeWallet,
        uint256 totalTokensGranted,
        uint64 vestingDuration,
        uint64 startTime,
        uint64 vestingFrequency,
        uint64 lockInPeriod,
        VestingStatus status
    );
    event VestingCancelled(address indexed employeeWallet);
    event VestedTokensTransferred(
        address indexed employeeWallet,
        uint256 tokensTransferred
    );

    // require error strings
    // OWNER_NO_BALANCE - Insufficient balance of msg.sender
    // CONTRACT_NO_BALANCE - Insufficient balance if contract
    // TRANSFER_FAILED - Unable to transfer tokens to Vesting Account.
    // NOT_OWNER - Only owner of this contract can call this function
    // RESTRICTED_CALL - Only Employee who owns this contract OR company can call it
    // VESTING_NOT_ACTIVE - Vesting is not active

    constructor(
        address _employeeWallet,
        IERC20 token,
        uint256 _totalTokensGranted,
        uint64 _vestingDuration,
        uint64 _startTime,
        uint64 _vestingFrequency,
        uint64 _lockInPeriod
    ) {
        require(
            token.balanceOf(msg.sender) >= totalTokensGranted,
            "OWNER_NO_BALANCE"
        );
        owner = msg.sender;
        _token = token;
        employeeWallet = _employeeWallet;
        totalTokensGranted = _totalTokensGranted;
        vestingDuration = _vestingDuration;
        startTime = _startTime;
        vestingFrequency = _vestingFrequency;
        lockInPeriod = _lockInPeriod;
        status = VestingStatus.NOT_ACTIVE;

        // console.log("msg sender", msg.sender);
        // console.log("contract address", address(this));
        // console.log('token balance', token.balanceOf(msg.sender));
        // console.log('total tokens granted', totalTokensGranted);
        // Transfer token from company wallet to this contract
        // bool _success = token.transfer(address(this), totalTokensGranted);
        // require(_success, "TRANSFER_FAILED");
        emit VestingCreated(
            employeeWallet,
            totalTokensGranted,
            vestingDuration,
            startTime,
            vestingFrequency,
            lockInPeriod,
            status
        );
    }

    /**
     * Modifier to be used for functions restricted to owner of this
     * contract
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    modifier callOnlyWhenActive() {
        require(status == VestingStatus.ACTIVE, "Contract is not active");
        _;
    }

    function contractAddress() external view returns (address) {
        return address(this);
    }

    /**
     * Activate vesting
     */
    function activate() external onlyOwner {
        // Check if contract has sufficient token balance to start vesting
        require(
            _token.balanceOf(address(this)) >= totalTokensGranted,
            "CONTRACT_NO_BALANCE"
        );
        contractCreateTime = block.timestamp;
        status = VestingStatus.ACTIVE;
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

    function getTokensVested() private view returns (uint256) {
        // Calculate the tokens vested till now
        uint256 tokensVested;
        // console.log("contractCreateTime", contractCreateTime, startTime, block.timestamp);
        if (contractCreateTime + startTime < block.timestamp) {
            // Calculate the tokens vested per vesting frequency
            uint64 vestingCycles = vestingDuration / vestingFrequency;
            uint256 tokensVestedPerCycle = totalTokensGranted / vestingCycles;
            tokensVested =
                ((block.timestamp - contractCreateTime - startTime) /
                    vestingFrequency) *
                tokensVestedPerCycle;
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
    function getEmployeeVestingInfo()
        external
        view
        returns (VestingInfo memory)
    {
        // Check if employee OR owner is calling it
        require(
            (msg.sender == employeeWallet || msg.sender == owner),
            "RESTRICTED_CALL"
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
            tokensVested,
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
    function transferTokensToEmployeeWallet() external callOnlyWhenActive {
        // Check if employee OR owner is calling it
        require(
            (msg.sender == employeeWallet || msg.sender == owner),
            "RESTRICTED_CALL"
        );

        require(
            block.timestamp >= contractCreateTime + startTime + lockInPeriod,
            "LOCKINPERIOD_NOT_OVER"
        );

        uint256 tokensVested = getTokensVested();
        if (tokensVested > tokensTransferred) {
            uint256 tokensToTransfer = tokensVested - tokensTransferred;
            _token.transfer(employeeWallet, tokensToTransfer);
            tokensTransferred = tokensVested;
            emit VestedTokensTransferred(
                employeeWallet,
                uint64(tokensToTransfer)
            );
        }
    }
}
