// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/core/ProposeTransaction.sol";
import "src/core/Treasury.sol";
import "src/core/TimeLock.sol";
import "src/libraries/Errors.sol";
import "src/interfaces/IERC20.sol";
import {ClaimIncentives} from "src/modules/ClaimIncentives.sol";

contract ProposeTransactionTest is Test {
    ProposeTransaction public propose;
    Treasury public treasury;
    TimeLock public timeLock;
    IERC20 public token;

    address[] public approvers;
    address public user = makeAddr("user");
    address public approver1 = makeAddr("approver1");
    address public approver2 = makeAddr("approver2");
    address public attacker = makeAddr("attacker");

    ClaimIncentives public claimContract;
    address public admin = makeAddr("admin");

    function getTransaction(
        uint id
    ) internal view returns (ProposeTransaction.Transaction memory t) {
        (
            t.id,
            t.nonce,
            t.value,
            t.recipient,
            t.proposer,
            t.amount,
            t.proposalFee,
            t.noOfApprovals,
            t.threshold,
            t.queue,
            t.executed,
            t.cancelled,
            t.timeProposed,
            t.startTime,
            t.stopTime
        ) = propose.proposedTransactions(id);
    }

    function setUp() public {
        token = IERC20(address(new EzeERC20()));

        timeLock = new TimeLock();
        timeLock.setLockTime(3600);

        approvers.push(approver1);
        approvers.push(approver2);

        treasury = new Treasury(address(token));
        EzeERC20(address(token)).mint(address(treasury), 1000 ether);

        propose = new ProposeTransaction(
            2,
            2,
            approvers,
            address(timeLock),
            address(treasury)
        );

        vm.deal(user, 5 ether);
        vm.deal(approver1, 5 ether);
        vm.deal(approver2, 5 ether);
        vm.deal(attacker, 5 ether);

        bytes32 dummyRoot = keccak256(abi.encodePacked("root"));
        claimContract = new ClaimIncentives(address(token), dummyRoot, admin);

        EzeERC20(address(token)).mint(address(claimContract), 500 ether);
    }

    function testProposeTransaction() public {
        vm.prank(user);
        propose.proposeTransaction{value: 1 ether}(100, address(user), 50);

        ProposeTransaction.Transaction memory t = getTransaction(1);
        assertEq(t.proposer, user);
        assertEq(t.value, 100);
        assertEq(t.amount, 50);
    }

    function testApproveTransaction() public {
        vm.prank(user);
        propose.proposeTransaction{value: 1 ether}(100, address(user), 50);

        vm.prank(approver1);
        propose.approveTransaction{value: 1 ether}(1);

        ProposeTransaction.Transaction memory t = getTransaction(1);
        assertEq(t.noOfApprovals, 1);
        assertFalse(t.queue);

        vm.prank(approver2);
        propose.approveTransaction{value: 1 ether}(1);

        t = getTransaction(1);
        assertEq(t.noOfApprovals, 2);
        assertTrue(t.queue);
    }

    // --- Negative / Exploit Tests ----

    function testCannotApproveTwice() public {
        vm.prank(user);
        propose.proposeTransaction{value: 1 ether}(100, address(user), 50);

        vm.prank(approver1);
        propose.approveTransaction{value: 1 ether}(1);

        vm.prank(approver1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.TransactionAlreadyApproved.selector,
                1,
                approver1
            )
        );
        propose.approveTransaction{value: 1 ether}(1);
    }

    function testCannotExecuteBeforeTimelock() public {
        vm.prank(user);
        propose.proposeTransaction{value: 1 ether}(100, address(user), 50);

        vm.prank(approver1);
        propose.approveTransaction{value: 1 ether}(1);
        vm.prank(approver2);
        propose.approveTransaction{value: 1 ether}(1);

        ProposeTransaction.Transaction memory t = getTransaction(1);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.TimelockNotExpired.selector,
                t.stopTime
            )
        );
        propose.execute(1);
    }

    function testNonApproverCannotApprove() public {
        vm.prank(user);
        propose.proposeTransaction{value: 1 ether}(100, address(user), 50);

        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.NotApprover.selector, attacker)
        );
        propose.approveTransaction{value: 1 ether}(1);
    }

    function testCannotApproveOwnTransaction() public {
        vm.prank(user);
        propose.proposeTransaction{value: 1 ether}(100, address(user), 50);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.NotApprover.selector, user)
        );
        propose.approveTransaction{value: 1 ether}(1);
    }

    function testCannotCancelTwice() public {
        vm.prank(user);
        propose.proposeTransaction{value: 1 ether}(100, address(user), 50);

        vm.prank(approver1);
        propose.cancel(1);

        vm.prank(approver1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.TransactionAlreadyCancelled.selector,
                1
            )
        );
        propose.cancel(1);
    }

    function testInvalidProposalFee() public {
        vm.prank(user);
        propose.proposeTransaction{value: 1 ether}(100, address(user), 50);

        vm.prank(approver1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InvalidProposalFee.selector,
                0.5 ether
            )
        );
        propose.approveTransaction{value: 0.5 ether}(1);
    }

     function testAdminCanUpdateMerkleRoot() public {
        bytes32 newRoot = keccak256(abi.encodePacked("newroot"));
        vm.prank(admin);
        claimContract.setMerkleRoot(newRoot);
        assertEq(claimContract.merkleRoot(), newRoot);
    }


    function testInvalidProofFails() public {
        bytes32[] memory invalidProof;
        vm.prank(attacker);
        vm.expectRevert("Invalid proof");
        claimContract.claim(50 ether, invalidProof);
    }

}

// ----- Eze ERC20 for Treasury -----

contract EzeERC20 is IERC20 {
    string public name = "EzeERC20";
    string public symbol = "ANT";
    uint8 public decimals = 18;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    function transfer(address to, uint value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient");
        require(allowance[from][msg.sender] >= value, "Not allowed");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function mint(address to, uint value) external {
        balanceOf[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
    }
}
