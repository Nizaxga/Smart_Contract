
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Convert.sol";
import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPS {
    
    CommitReveal public commitReveal;
    Convert public convert;
    TimeUnit public timeUnit;

    uint public numPlayer = 0;
    uint private count = 0;
    uint public reward = 0;

    mapping(address => bytes32) public player_commit;
    mapping(address => uint) public player_choice;
    mapping(address => bool) public player_not_played;
    mapping(address => bool) public hasCommitted;

    address[] public players;
    address[] private TheBoys = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    uint public numInput = 0;
    uint public gameStartTime;
    uint public commitStartTime;
    uint public TimeOut = 300;

    constructor(address _commitReveal, address _convert, address _timeUnit) {
        commitReveal = CommitReveal(_commitReveal);
        convert = Convert(_convert);
        timeUnit = TimeUnit(_timeUnit);
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
        if (numPlayer == 1) {
            timeUnit.setStartTime();
            gameStartTime = block.timestamp;
        }
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
    function commit(uint choice) public  {
        require(numPlayer == 2);
        require(player_not_played[msg.sender]);
        require(choice >= 0 && choice <= 4);
        bytes32 converted = convert.convert(choice);
        bytes32 hashed = convert.getHash(converted);
        commitReveal.commit(hashed, msg.sender);
        player_not_played[msg.sender] = false;
        numInput++;
    }

    function reveal(bytes32 hash) public {
        require(numPlayer == 2);
        require(numInput == 2);
        commitReveal.reveal(hash, msg.sender);
        uint choice = convert.reverse(hash);
        player_choice[msg.sender] = choice;
        count++;
        if(count == 2){
            _checkWinnerAndPay();
        }
    }

    function refund() public {
        if (numPlayer == 1 && timeUnit.elapsedSeconds() >= TimeOut) {
            address payable firstPlayer = payable(players[0]);
            firstPlayer.transfer(reward);
        } else if (numPlayer == 2 && numInput == 1 && timeUnit.elapsedSeconds() >= TimeOut) {
            address payable firstPlayer = payable(players[0]);
            address payable secondPlayer = payable(players[1]);
            firstPlayer.transfer(reward / 2);
            secondPlayer.transfer(reward / 2);
        }
        _resetGame();
    }

    function _resetGame() private {
        delete players;
        numPlayer = 0;
        reward = 0;
        numInput = 0;
    }

    function _checkWinnerAndPay() private {
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
        // Reset game state
        delete players;
        numPlayer = 0;
        reward = 0;
        numInput = 0;
    }
}