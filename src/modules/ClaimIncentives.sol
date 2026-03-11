// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract ClaimIncentives {
    IERC20 public token;
    bytes32 public merkleRoot;
    address public admin;

    mapping(address => bool) public hasClaimed;

    event Claimed(address indexed user, uint256 amount);
    event MerkleRootUpdated(bytes32 newRoot);


    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

  
    constructor(address _token, bytes32 _merkleRoot, address _admin) {
        token = IERC20(_token);
        merkleRoot = _merkleRoot;
        admin = _admin;
    }

    function setMerkleRoot(bytes32 _root) external onlyAdmin {
        merkleRoot = _root;
        emit MerkleRootUpdated(_root);
    }

  
    function claim(uint256 amount, bytes32[] calldata proof) external {
        require(!hasClaimed[msg.sender], "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        hasClaimed[msg.sender] = true;
        require(token.transfer(msg.sender, amount), "Transfer failed");

        emit Claimed(msg.sender, amount);
    }
}