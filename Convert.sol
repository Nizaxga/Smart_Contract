// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <=0.9.0;

contract Convert {
    function convert(uint256 n) public view returns (bytes32) {
        require(n <= 4 && n >= 0, "Invalid choice"); // Ensuring choice is 00, 01, or 02
        bytes32 randPart = keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty));
        uint256 maskedRand = uint256(randPart) & 
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00; 
        uint256 finalValue = maskedRand | n;
        return bytes32(finalValue);
    }
    function reverse(bytes32 data) public pure returns (uint256) {
        uint256 value = uint256(data);
        return value & 0xFF; // Extract the last byte (player's choice)
    }
    function getHash(bytes32 data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }
    function getAddress() public view returns (address) {
        return address(this);
    }
}