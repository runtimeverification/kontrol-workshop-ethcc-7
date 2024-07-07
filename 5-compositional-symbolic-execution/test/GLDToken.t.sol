// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GLDToken} from "../src/GLDToken.sol";
import {KontrolCheats} from "kontrol-cheatcodes/KontrolCheats.sol";

contract GLDTokenTest is Test, KontrolCheats {
    GLDToken public gld;

    address constant DEPLOYED_ERC20 = address(491460923342184218035706888008750043977755113263);
    address constant FOUNDRY_TEST_CONTRACT = address(728815563385977040452943777879061427756277306518);
    address constant FOUNDRY_CHEAT_CODE = address(645326474426547203313410069153905908525362434349);

    uint256 constant MAX_INT = 2 ** 256 - 1;

    function _notBuiltinOrPrecompiledAddress(address addr) internal pure {
        vm.assume(addr != FOUNDRY_CHEAT_CODE);
        vm.assume(addr != FOUNDRY_TEST_CONTRACT);
        vm.assume(addr != DEPLOYED_ERC20);
        vm.assume(uint256(uint160(addr)) == 0 || 9 < uint256(uint160(addr)));
    }

    function hashedLocation(address _key, bytes32 _index) public pure returns (bytes32) {
        // Returns the index hash of the storage slot of a map at location `index` and the key `_key`.
        // returns `keccak(#buf(32,_key) +Bytes #buf(32, index))
        return keccak256(abi.encode(_key, _index));
    }

    modifier unchangedStorage(bytes32 storageSlot) {
        bytes32 initialStorage = vm.load(address(gld), storageSlot);
        _;
        bytes32 finalStorage = vm.load(address(gld), storageSlot);
        assertEq(initialStorage, finalStorage);
    }

    function setUp() public {
        gld = new GLDToken();
        kevm.symbolicStorage(address(gld));
    }

    /**
     * transfer() checks.
     */
    function testTransferFailure_0(address to, uint256 value, bytes32 storageSlot)
        public
        unchangedStorage(storageSlot)
    {
        vm.startPrank(address(0));
        bytes4 errorSelector = bytes4(keccak256("ERC20InvalidSender(address)"));
        vm.expectRevert(abi.encodeWithSelector(errorSelector, address(0)));
        gld.transfer(to, value);
    }

    function testTransferConsecutive(address alice, address bob, uint256 amount, bytes32 storageSlot)
        public
        unchangedStorage(storageSlot)
    {
        vm.assume(alice != address(0));
        vm.assume(bob != address(0));
        _notBuiltinOrPrecompiledAddress(alice);
        _notBuiltinOrPrecompiledAddress(bob);
        uint256 balanceAlice = gld.balanceOf(alice);
        uint256 balanceBob = gld.balanceOf(bob);
        vm.assume(balanceAlice >= amount);
        vm.assume(balanceBob <= MAX_INT - amount);
        vm.prank(alice);
        gld.transfer(bob, amount);
        vm.prank(bob);
        gld.transfer(alice, amount);
    }
}
