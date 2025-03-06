# Rock Paper Scissors Lizard Spock

## Reset Game
```solidity
function _resetGame() private {
        delete players;
        numPlayer = 0;
        reward = 0;
        numInput = 0;
    }
```
ทำการ reset ตัวแปรทั้งหมด เรียกใช้ใน Refund, Decide winner function

## การป้องกันการล็อกเงินใน Contract
```solidity
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
```
ถ้าผู้เล่นคนแรกเข้ามาแต่ไม่มีคนที่สองจะสามารถขอเงินคืนได้ เงินจะถูกคืนให้หลังจากหมดเวลา
ถ้ามีผู้เล่นสองคนแต่มีเพียงคนเดียวที่เลือกจะสามารถขอเงินคืนได้ เงินจะถูกแบ่งคืนให้ทั้งสองคนหลังจากหมดเวลา
ใช้ `elapsedSeconds()` จาก `TimeUnit.sol` ในการดูว่าผ่านไปนานแค่ไหนแล้ว โดย `setStartTime()` ถูกเรียกหลังจาก `addplayer()` หรือมี player 1 commitChoice มาแล้ว

## การซ่อน Choice และ Commit-Reveal

```solidity
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
```
ผู้เล่นทำการ **commit** โดยใช้ `convert.convert(choice)` และ `commitReveal.commit()` 
ค่า hash ของตัวเลือกจะถูกบันทึกแทนค่าจริงเพื่อป้องกันการเปิดเผยตัวเลือกก่อนเวลาอันควร
หลังจากนั้นเมื่อทั้ง 2 commit แล้วจะสามารถ **reveal** เพื่อแสดง choice ที่เลือกโดยต้องใช้ค่าที่โดน `convert.convert()` ในตอนแรก

## การจัดการเวลารอผู้เล่นไม่ครบสองคน
ใน `addPlayer()` หากเป็นผู้เล่นคนแรก เวลาจะถูกบันทึกไว้โดย `timeUnit.setStartTime();`
`refund()` จะตรวจสอบว่าผู้เล่นเข้ามาเกินเวลาหรือไม่
เมื่อถึงกำหนดเวลากำหนด (เช่น 5 นาที) เงินจะถูกคืนให้ผู้เล่น

```solidity
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
```

## การตัดสินผู้ชนะ
```solidity
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
```

เมื่อผู้เล่นทั้งสองคน commit ตัวเลือกแล้ว เกมจะทำการเปิดเผยและตัดสินผู้ชนะโดยอัตโนมัติ
เปรียบเทียบตัวเลือกของผู้เล่นและโอนรางวัลให้ผู้ชนะ
ถ้าผลเสมอ เงินรางวัลจะถูกแบ่งครึ่ง
หลังจากเกมจบ `resetGame()` จะถูกเรียกใช้เพื่อเตรียมสำหรับรอบถัดไป