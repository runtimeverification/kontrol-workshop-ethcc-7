// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Vm} from "forge-std/Vm.sol";

abstract contract SaveAddress {
    string public constant folder = "state-dump/";
    string public constant dumpStateFile = "StateDump.json";
    string public constant addressNamesFile = "AddressNames.json";

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function save_address(address addr, string memory name) public {
        string memory address_names_file = check_file(folder, addressNamesFile);
        vm.writeJson({json: vm.serializeString("", vm.toString(addr), name), path: address_names_file});
    }

    /// @notice Checks if dir_name/file_name exists and creates it if not
    function check_file(string memory dir_name, string memory file_name) public returns (string memory) {
        string memory dirname = string.concat(vm.projectRoot(), "/", dir_name);
        string memory filename = string.concat(vm.projectRoot(), "/", dir_name, "/", file_name);
        if (vm.exists(filename)) return filename;
        if (!vm.isDir(dirname)) ffi_two_arg("mkdir", "-p", dirname); // Create directory if doesn't exist
        ffi_one_arg("touch", filename); // Create file. Might be redundant, but better make sure
        return filename;
    }

    /// @notice Execute one bash command with one argument
    /// @dev    Will revert if the command returns any output
    /// TODO: abstract number of arguments per function
    function ffi_one_arg(string memory command, string memory arg) public {
        string[] memory inputs = new string[](2);
        inputs[0] = command;
        inputs[1] = arg;
        bytes memory res = vm.ffi(inputs);
        require(res.length == 0, "RecordState: Command execution failed");
    }

    /// @notice Execute one bash command with one argument
    /// @dev    Will revert if the command returns any output
    /// TODO: abstract number of arguments per function
    function ffi_two_arg(string memory command, string memory arg1, string memory arg2) public {
        string[] memory inputs = new string[](3);
        inputs[0] = command;
        inputs[1] = arg1;
        inputs[2] = arg2;
        bytes memory res = vm.ffi(inputs);
        require(res.length == 0, "RecordState: Command execution failed");
    }
}
