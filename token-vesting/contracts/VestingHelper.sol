// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract VestingHelper {
    enum ContractState {NOT_CREATED, ACTIVE, DELETED, SUSPENDED}
    ContractState private state;

    constructor() {
        state = ContractState.ACTIVE;
    }

    function contractAddress() external view returns(address) {
        return address(this);
    }

    modifier callOnlyWhenActive() {
        require(state == ContractState.ACTIVE, "Contract is not active");
        _;
    }

    function deleteContract() internal {
        state = ContractState.DELETED;
    }

    function suspendContract() internal {
        state = ContractState.SUSPENDED;
    }

    function activateContract() internal {
        state = ContractState.ACTIVE;
    }
}