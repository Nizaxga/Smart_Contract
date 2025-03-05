
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Convert.sol";
import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPS {
    CommitReveal public commitReveal;
    Convert public convert;

    uint public numPlayer = 0;
    uint public reward = 0;

    mapping(address => bytes32) public player_commit;
    mapping (address => uint) public player_choice;
    mapping (address => bool) public player_not_played;

    mapping(address => bool) public hasCommitted;

    address[] public players;
    address[] private TheBoys = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    uint public numInput = 0;

    constructor(address _commitReveal, address _convert) {
        commitReveal = CommitReveal(_commitReveal);
        convert = Convert(_convert);
    }

    function bouncer(address _player) private view returns (bool) {
        for (uint i = 0; i < TheBoys.length; i++) {
            if (TheBoys[i] == _player) {
                return true;
            }
        }
        return false;
    }

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(bouncer(msg.sender));
        if (numPlayer > 0) {
            require(msg.sender != players[0]);      
        }
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }

    // function input(uint choice) public  {
    //     require(numPlayer == 2);
    //     require(player_not_played[msg.sender]);
    //     require(choice >= 0 && choice <= 4);
    //     player_choice[msg.sender] = choice;
    //     player_not_played[msg.sender] = false;
    //     numInput++;
    //     if (numInput == 2) {
    //         _checkWinnerAndPay();
    //     }
    // }

    function commitMove(uint choice) public {
        require(numPlayer == 2, "Not enough players");
        require(!hasCommitted[msg.sender], "Already committed");
        require(choice >= 0 && choice <= 4, "Invalid choice");
        bytes32 convertedChoice = convert.convert(choice);
        bytes32 commitment = convert.getHash(convertedChoice);
        commitReveal.commit(commitment);
        player_commit[msg.sender] = commitment;
        player_choice[msg.sender] = choice;
        hasCommitted[msg.sender] = true;
        numInput++;
        if (numInput == 2) {
            _revealAndDecideWinner();
        }
    }

    function _revealAndDecideWinner() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        if (
            (p0Choice == 0 && (p1Choice == 2 || p1Choice == 3)) ||
            (p0Choice == 1 && (p1Choice == 0 || p1Choice == 4)) || 
            (p0Choice == 2 && (p1Choice == 1 || p1Choice == 3)) || 
            (p0Choice == 3 && (p1Choice == 4 || p1Choice == 1)) ||
            (p0Choice == 4 && (p1Choice == 2 || p1Choice == 0)) 
        ) {
            account0.transfer(reward);
        } else if (
            (p1Choice == 0 && (p0Choice == 2 || p0Choice == 3)) ||
            (p1Choice == 1 && (p0Choice == 0 || p0Choice == 4)) ||
            (p1Choice == 2 && (p0Choice == 1 || p0Choice == 3)) ||
            (p1Choice == 3 && (p0Choice == 4 || p0Choice == 1)) ||
            (p1Choice == 4 && (p0Choice == 2 || p0Choice == 0))
        ) {
            account1.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        delete players;
        numPlayer = 0;
        reward = 0;
        numInput = 0;
    }

    // function _checkWinnerAndPay() private {
    //     uint p0Choice = player_choice[players[0]];
    //     uint p1Choice = player_choice[players[1]];
    //     address payable account0 = payable(players[0]);
    //     address payable account1 = payable(players[1]);
    //     if (
    //         (p0Choice == 0 && (p1Choice == 2 || p1Choice == 3)) ||
    //         (p0Choice == 1 && (p1Choice == 0 || p1Choice == 4)) || 
    //         (p0Choice == 2 && (p1Choice == 1 || p1Choice == 3)) || 
    //         (p0Choice == 3 && (p1Choice == 4 || p1Choice == 1)) ||
    //         (p0Choice == 4 && (p1Choice == 2 || p1Choice == 0)) 
    //     ) {
    //         account0.transfer(reward);
    //     } else if (
    //         (p1Choice == 0 && (p0Choice == 2 || p0Choice == 3)) ||
    //         (p1Choice == 1 && (p0Choice == 0 || p0Choice == 4)) ||
    //         (p1Choice == 2 && (p0Choice == 1 || p0Choice == 3)) ||
    //         (p1Choice == 3 && (p0Choice == 4 || p0Choice == 1)) ||
    //         (p1Choice == 4 && (p0Choice == 2 || p0Choice == 0))
    //     ) {
    //         account1.transfer(reward);
    //     } else {
    //         account0.transfer(reward / 2);
    //         account1.transfer(reward / 2);
    //     }
    //     // Reset game state
    //     delete players;
    //     numPlayer = 0;
    //     reward = 0;
    //     numInput = 0;
    // }
}