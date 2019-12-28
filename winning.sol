pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

library Utils {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }


    function sameDay(uint day1, uint day2) internal pure returns (bool){
                return day1 / 24 / 3600 == day2 / 24 / 3600;
    }

    function bytes32Eq(bytes32 a, bytes32 b) internal pure returns (bool) {
        for (uint i = 0; i < 32; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        uint charCount = 0;
        bytes memory bytesString = new bytes(32);
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            } else if (charCount != 0) {
                break;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];

        }
        return string(bytesStringTrimmed);
    }

    function _stringToBytes(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _stringEq(string a, string b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return _stringToBytes(a) == _stringToBytes(b);
        }
    }


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;

    }
}

contract SeroInterface {

    bytes32 private topic_sero_issueToken = 0x3be6bf24d822bcd6f6348f6f5a5c2d3108f04991ee63e80cde49a8c4746a0ef3;
    bytes32 private topic_sero_balanceOf = 0xcf19eb4256453a4e30b6a06d651f1970c223fb6bd1826a28ed861f0e602db9b8;
    bytes32 private topic_sero_send = 0x868bd6629e7c2e3d2ccf7b9968fad79b448e7a2bfb3ee20ed1acbc695c3c8b23;
    bytes32 private topic_sero_currency = 0x7c98e64bd943448b4e24ef8c2cdec7b8b1275970cfe10daf2a9bfa4b04dce905;

    function sero_msg_currency() internal returns (string) {
        bytes memory tmp = new bytes(32);
        bytes32 b32;
        assembly {
            log1(tmp, 0x20, sload(topic_sero_currency_slot))
            b32 := mload(tmp)
        }
        return Utils.bytes32ToString(b32);
    }

    function sero_issueToken(uint256 _total, string memory _currency) internal returns (bool success){
        bytes memory temp = new bytes(64);
        assembly {
            mstore(temp, _currency)
            mstore(add(temp, 0x20), _total)
            log1(temp, 0x40, sload(topic_sero_issueToken_slot))
            success := mload(add(temp, 0x20))
        }
        return;
    }

    function sero_balanceOf(string memory _currency) internal returns (uint256 amount){
        bytes memory temp = new bytes(32);
        assembly {
            mstore(temp, _currency)
            log1(temp, 0x20, sload(topic_sero_balanceOf_slot))
            amount := mload(temp)
        }
        return;
    }

    function sero_send_token(address _receiver, string memory _currency, uint256 _amount) internal returns (bool success){
        return sero_send(_receiver, _currency, _amount, "", 0);
    }

    function sero_send(address _receiver, string memory _currency, uint256 _amount, string memory _category, bytes32 _ticket) internal returns (bool success){
        bytes memory temp = new bytes(160);
        assembly {
            mstore(temp, _receiver)
            mstore(add(temp, 0x20), _currency)
            mstore(add(temp, 0x40), _amount)
            mstore(add(temp, 0x60), _category)
            mstore(add(temp, 0x80), _ticket)
            log1(temp, 0xa0, sload(topic_sero_send_slot))
            success := mload(add(temp, 0x80))
        }
        return;
    }

}


contract Config {

    uint256 constant MINSERO = 1e10;//最小投资(测试可修改)
    uint256 constant MAXSERO = 1e22;//最大投资
    uint256 constant ONESERO = 1e18;//1个SERO的值

    uint256 constant MAXPLAYER = 255;//每桌最大人数
    uint256 constant HOLDSECONDS = 30; //停止下注时间
    uint256 constant FEE = 1; //每注手续费率（百分之）
    uint256 constant CLOSEFEE = 5; //每桌关闭手续费（百分之）
    uint256 constant REFERREDFEE = 5;//推荐人手续费(千分之)
    uint256 constant MAXDESKFEE = 100;//桌主每桌最大手续费（千分之）
}

contract Ownable {

    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function _getOwner() internal view returns(address){
        return owner;
    }
}

interface RelationService {
    function getRelationship(address addr) external view returns(address, address, address[]);

    function setRelationship(address referrerAddr, address downAddr) external returns(bool);

    function getRelationDownNum(address addr) external view returns(uint256);

    function getEncodeIndexByAddr(address addr) external view returns(string);

    function getUserAddrByEncodeId(string idcode) external view returns(address);
}

contract Winning is Config, SeroInterface, Ownable {

    string private constant SERO_CURRENCY = "SERO";
    bool private _isDebug;
    uint256 private _fee;
    uint256 private _closefee;
    uint256 private _referrefee;
    RelationService private _relationService;

    enum TableStatus{
        stop,
        start,
        destory
    }

    struct Player{
        uint256 rand;//幸运数
        address addr;//投资人
    }

    struct Game {
        uint256 startTimeStamp;//每局开始时间
        uint256 amount;//总金额(实际值)
        uint256 playerNum;//玩家数
        uint256 lotteryTimeStamp;//开奖时间
        uint256 winnerId; //中奖人id
        bool end;//结束标记

        mapping(uint256 => Player) playerList;//玩家列表
    }

    struct Table {
        uint256 times;//游戏局数
        uint256 maxPlayer; //最大人数
        uint256 single;//单注金额
        uint256 intervalSeconds;//开局间隔
        uint256 pledgeAmount;//质押资金
        TableStatus status; //状态
        uint256 fee; //千分之几的费率
        address creator;//创建者

        mapping(uint256 => Game) gameList;//游戏列表
    }

    struct PlayerDetail{
        uint256 tabId;//桌子id
        uint256 times; //局数
        uint256 playerNum;//投注数
        bool isWinner;//是否中奖
    }

    struct PlayerShow{
        uint256 num;
        mapping(uint256=>PlayerDetail) detail;
    }

    Table[] private _tables;//游戏桌
    PlayerShow[] _allPlayerShow;//索引
    mapping(address=>uint256) _playerIndex;

    mapping(address=>uint256) _frozen;//用户冻结总金额
    mapping(address=>uint256) _deposit;//用户充值总金额
    mapping(address=>uint256) _balance;//用户余额
    mapping(address=>uint256) _withdraw;//用户取款总金额

    uint256 private _playerCount;//玩家数
    uint256 private _allIncome;//所有收入
    uint256 private _allOutlay;//所有支出
    address private _marketAddr;//市场地址

    event TableCreated(uint256, uint256, uint256, uint256);//tabid, maxplayer, single, interval
    event GamePlaying(uint256, uint256, uint256, uint256, uint256);//tabid, times, startTimeStamp, amount, playerNum
    event GameJoined(uint256, uint256, address);//tabid, times, addr
    event GameEnded(uint256, uint256, uint8, address);//tabid, times, winnerIndex, addr

    using SafeMath for uint256;

    constructor(address _market, address _relation, bool _debug) public  {
        if(!Utils.isContract(_market)){
            _marketAddr = _market;
        }
        _isDebug = _debug;
        _relationService = RelationService(_relation);
        _fee = FEE;
        _closefee = CLOSEFEE;
        _referrefee = REFERREDFEE;
        _tables.push(Table({times: 0, maxPlayer: MAXPLAYER, single: 0, intervalSeconds: 0, pledgeAmount: 0, status: TableStatus.stop, fee: 0, creator: address(0)}));
        _allPlayerShow.push(PlayerShow({num:0}));
    }

    function setMarket(address _market) public onlyOwner{
        _marketAddr = _market;
    }

    function setRelationService(address _relation) public onlyOwner{
        _relationService = RelationService(_relation);
    }

    function getTablesCount() public view returns(uint256){
        return _tables.length.sub(1);
    }

    function getAllIncome() public onlyOwner view returns(uint256){
        return _allIncome;
    }

    function getOutlay() public onlyOwner view returns(uint256){
        return _allOutlay;
    }

    function setFee(uint256 fee) public onlyOwner{
        _fee = fee;
    }

    function getFee() public view returns(uint256){
        return _fee;
    }

    function setCloseFee(uint256 closeFee) public onlyOwner{
        _closefee = closeFee;
    }

    function getCloseFee() public view returns(uint256){
        return _closefee;
    }

    function setReferreFee(uint256 referreFee) public onlyOwner{
        _referrefee = referreFee;
    }

    function getReferreFee() public view returns(uint256){
        return _referrefee;
    }

    function balanceOfSero() public  returns (uint256){
        return sero_balanceOf(SERO_CURRENCY);
    }

    function getPlayerBalance() public view returns(uint256){
        return _balance[msg.sender];
    }

    function getPlayerDeposit() public view returns(uint256){
        return _deposit[msg.sender];
    }

    function getPlayerWithDraw() public view returns(uint256){
        return _withdraw[msg.sender];
    }

    function getPlayerFrozen() public view returns(uint256){
        return _frozen[msg.sender];
    }

    function getPlayerCapital() public view returns(uint256, uint256, uint256, uint256){
        return (_deposit[msg.sender], _frozen[msg.sender], _balance[msg.sender], _withdraw[msg.sender]);
    }

    function _getStatusByEnum(TableStatus status) internal pure returns(uint256){
        if(status == TableStatus.stop){
            return uint256(0);
        }else if(status == TableStatus.start){
            return uint256(1);
        }else{
            return uint256(2);
        }
    }

    function getRelationDownNum() public view returns(uint256){
        return _relationService.getRelationDownNum(msg.sender);
    }

    function getRelationship() public view returns(address, address, address[]){
        return _relationService.getRelationship(msg.sender);
    }

    function getRelationEncodeId() public view returns(string){
        return _relationService.getEncodeIndexByAddr(msg.sender);
    }

    function setRelationship(address referrerAddr) public returns(bool){
        return _relationService.setRelationship(referrerAddr, msg.sender);
    }

    function getMyReferrerCode() public view returns(string){
        return _relationService.getEncodeIndexByAddr(msg.sender);
    }

    function _getStatusByUint(uint256 status) internal pure returns(TableStatus){
        if(status == uint256(0)){
            return TableStatus.stop;
        }else if(status == uint256(1)){
            return TableStatus.start;
        }else{
            return TableStatus.destory;
        }
    }

    function _sendBaseBonus(uint256 amount) private{
        uint256 fee = amount.div(2);
        address ownerAddr = _getOwner();

        if(!_isDebug && !Utils.isContract(ownerAddr) && !Utils.isContract(_marketAddr)){
            _balance[ownerAddr] = _balance[ownerAddr].add(fee);
            _balance[_marketAddr] = _balance[_marketAddr].add(fee);
        }
    }

    function _sendBonus(address winner, Table storage table, uint256 amount) private{
        uint256 allFee = amount.mul(_fee).div(100);
        uint256 creatorfee = amount.mul(table.fee).div(1000);
        uint256 winnerBonus = amount.sub(allFee.add(creatorfee));

        _allOutlay = _allOutlay.add(amount);
        if(!_isDebug && !Utils.isContract(winner) && !Utils.isContract(table.creator)){
            _balance[winner] = _balance[winner].add(winnerBonus);
            _balance[table.creator] = _balance[table.creator].add(creatorfee);
        }
        _sendBaseBonus(allFee);
    }

    function getAddr() public view returns(address){
        return msg.sender;
    }

    function getTableByPlayerNum(uint256 min, uint256 max) public view returns(uint256[]){
        uint256 count;

        for(uint256 i = 1; i < _tables.length; i++){
            if(_tables[i].maxPlayer >= min && _tables[i].maxPlayer <= max){
                count = count.add(1);
            }
        }

        uint256[] memory ids = new uint256[](count);
        uint256 n = 0;
        for(i = 1; i < _tables.length; i++){
            if(_tables[i].maxPlayer >= min && _tables[i].maxPlayer <= max){
                ids[n] = i;
                n = n.add(1);
            }
        }

        return (ids);
    }

    function getTableBySingle(uint256 min, uint256 max) public view returns(uint256[]){
        uint256 count;
        min = min.mul(ONESERO);
        max = max.mul(ONESERO);

        for(uint256 i = 1; i < _tables.length; i++){
            if(_tables[i].single >= min && _tables[i].single <= max){
                count = count.add(1);
            }
        }

        uint256[] memory ids = new uint256[](count);
        uint256 n = 0;
        for(i = 1; i < _tables.length; i++){
            if(_tables[i].single >= min && _tables[i].single <= max){
                ids[n] = i;
                n = n.add(1);
            }
        }

        return (ids);
    }

    function getTablesCountByStatus(uint256 status, bool isInclude) public view returns(uint256){
        uint256 count;
        TableStatus s = _getStatusByUint(status);
        for(uint256 i = 1; i < _tables.length; i++){
            if(isInclude && _tables[i].status == s){
                count = count.add(1);
            }
            if(!isInclude && _tables[i].status != s){
                count = count.add(1);
            }
        }
        return count;
    }

    function getTablesByStatus(uint256 status, bool isInclude) public view returns(uint256[]){
        uint256 count = getTablesCountByStatus(status, isInclude);
        uint256[] memory ids = new uint256[](count);
        uint256 n = 0;

        TableStatus s = _getStatusByUint(status);
        for(uint256 i = 1; i < _tables.length; i++){
            if(isInclude && _tables[i].status == s){
                ids[n] = i;
                n = n.add(1);
            }
            if(!isInclude && _tables[i].status != s){
                ids[n] = i;
                n = n.add(1);
            }
        }

        return (ids);
    }

    function getPlayersTables(address addr) public view returns(uint256[]){
        uint256 count;
        for(uint256 i = 1; i < _tables.length; i++){
            if(_tables[i].creator == addr){
                count = count.add(1);
            }
        }

        uint256[] memory ids = new uint256[](count);
        uint256 n = 0;
        for(i = 1; i < _tables.length; i++){
            if(_tables[i].creator == addr){
                ids[n] = i;
                n = n.add(1);
            }
        }

        return (ids);
    }

    function createTable(uint256 interval, uint256 maxPlayer, uint256 single, uint256 fee) public payable returns(uint256){
        if(!_isDebug){
            require(Utils._stringEq(SERO_CURRENCY, sero_msg_currency()), "Unacceptable assets");
        }
        require(!Utils.isContract(msg.sender), "Contract call not allowed");
        require(msg.value >= MINSERO && msg.value <= MAXSERO, "Exceeding the allowable range of assets");
        single = single.mul(ONESERO);
        require(msg.value == maxPlayer.mul(single), "The amount of mortgage is inconsistent with the quantity required");
        require(maxPlayer > 1 && maxPlayer <= MAXPLAYER, "Exceeded the maximum number of players");
        require(interval >= 2 * HOLDSECONDS, "Each time is at least twice the lock time");
        require(fee <= MAXDESKFEE, "The handling fee is too large");


        _tables.push(Table({times: 0, maxPlayer: maxPlayer, single: single, intervalSeconds: interval, pledgeAmount: msg.value, status: TableStatus.stop, fee: fee, creator: msg.sender}));
        emit TableCreated(_tables.length.sub(1), maxPlayer, msg.value, interval);

        _allIncome = _allIncome.add(msg.value);
        _frozen[msg.sender] = _frozen[msg.sender].add(msg.value);
        _deposit[msg.sender] = _deposit[msg.sender].add(msg.value);

        return _tables.length - 1;
    }

    function _startJoin(uint256 tabId,  uint256 rand, uint256 amount, uint256 x, bool isBalance) internal returns(bool){
        require(amount >= MINSERO && amount <= MAXSERO, "Exceeding the allowable range of assets");
        require(tabId > 0 && tabId < _tables.length, "More than the number of tables");

        Table storage table = _tables[tabId];
        require(table.status != TableStatus.destory, "The table has been destroyed");

        if(isBalance){
            _balance[msg.sender] = _balance[msg.sender].sub(amount);
        }else{
            _allIncome = _allIncome.add(amount);
        }

        if(table.status == TableStatus.stop){
            table.gameList[table.times] = Game({startTimeStamp: now, amount: 0, playerNum: 0, lotteryTimeStamp: 0, winnerId: 0, end: false});
            table.times = table.times.add(1);
            table.status = TableStatus.start;
        }


        Game storage game = table.gameList[table.times - 1];
        require(now >= game.startTimeStamp && now <= game.startTimeStamp.add(table.intervalSeconds).sub(HOLDSECONDS),
          "Not in betting time range");
        require(!game.end, "The game is over");
        require(amount == table.single.mul(x), "The number of bets is inconsistent with the amount paid");
        require(game.playerNum.add(x) <= Utils.min(MAXPLAYER, table.maxPlayer), "Bet bets exceed the maximum limit");

        emit GamePlaying(tabId, table.times, game.startTimeStamp, game.amount, game.playerNum.add(x));

        for(uint256 i = 0; i < x; i++){
            game.playerList[game.playerNum] = Player({rand: rand, addr: msg.sender});
            game.playerNum = game.playerNum.add(1);
            emit GameJoined(tabId, table.times, msg.sender);
        }
        addPlayer(tabId, table.times, x);

        game.amount = game.amount.add(amount);

        return true;
    }

    function withDraw() public returns(bool){
        require(!Utils.isContract(msg.sender), "Contract call not allowed");
        require(_balance[msg.sender] > 0, "Sorry, your credit is running low");

        uint256 amount = _balance[msg.sender];
        _balance[msg.sender] = 0;
        _withdraw[msg.sender] = _withdraw[msg.sender].add(amount);

        if(!_isDebug){
            require(sero_send_token(msg.sender, SERO_CURRENCY, amount), "Failed to send");
        }


        return true;
    }

    function joinGameFromBalance(uint256 tabId,  uint256 rand, uint256 x, uint256 amount) public returns(bool){
        require(!Utils.isContract(msg.sender), "Contract call not allowed");
        require(_balance[msg.sender] >= amount, "Sorry, your credit is running low");

        _frozen[msg.sender] = _frozen[msg.sender].add(amount);

        return _startJoin(tabId, rand, amount, x, true);
    }

    function joinGame(uint256 tabId,  uint256 rand, uint256 x, string referrerCode) public payable returns (bool){
        if(!_isDebug){
            require(Utils._stringEq(SERO_CURRENCY, sero_msg_currency()), "Unacceptable assets");
        }
        require(!Utils.isContract(msg.sender), "Contract call not allowed");

        address referrerAddr = _relationService.getUserAddrByEncodeId(referrerCode);
        _relationService.setRelationship(referrerAddr, msg.sender);

        _deposit[msg.sender] = _deposit[msg.sender].add(msg.value);
        _frozen[msg.sender] = _frozen[msg.sender].add(msg.value);

        return _startJoin(tabId, rand, msg.value, x, false);
    }

    function addPlayer(uint256 tabId, uint256 times, uint256 x) internal{
        uint256 index = _playerIndex[msg.sender];
        if( index == 0){
            _playerIndex[msg.sender] = _playerCount.add(1);
            index = _playerIndex[msg.sender];
            _allPlayerShow.push(PlayerShow({num:0}));
            _playerCount = _playerCount.add(1);
        }
        PlayerShow storage playerShow  = _allPlayerShow[index];
        playerShow.detail[playerShow.num] = PlayerDetail({tabId:tabId, times: times, playerNum: x, isWinner: false});
        playerShow.num = playerShow.num.add(1);
    }

    function detailOfTable(uint256 tabId) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, address){
        require(tabId >0 && tabId < _tables.length, "More than the number of tables");

        Table storage table = _tables[tabId];

        return(tabId, table.times, table.maxPlayer, table.single.div(ONESERO), table.intervalSeconds, table.pledgeAmount, _getStatusByEnum(table.status), table.fee, table.creator);
    }

    function detailOfGame(uint256 tabId, uint256 times) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool){
        require(tabId >0 && tabId < _tables.length, "More than the number of tables");

        Table storage table = _tables[tabId];
        require(table.times >0 && times <= table.times, "More than the number of games");

        Game storage game = table.gameList[times -1];

        return(tabId, times, game.startTimeStamp, game.playerNum.mul(table.single), game.playerNum, game.lotteryTimeStamp, game.winnerId, game.end);
    }

    function detailOfGamePlayer(uint256 tabId, uint256 times, uint256 playerId) public view returns(uint256, uint256, uint256, address, uint256){
        require(tabId >0 && tabId < _tables.length, "More than the number of tables");
        Table storage table = _tables[tabId];
        require(table.times >0 && times <= table.times, "More than the number of games");
        Game storage game = table.gameList[times -1];
        require(playerId >0 && playerId <= game.playerNum, "More than the number of players");
        Player storage player = game.playerList[playerId -1];

        uint256 rand = 0;
        if(game.end){
            rand = player.rand;
        }
        return (tabId, times, playerId, player.addr, rand);
    }

    function detailOfGamePlayerEx(uint256 tabId, uint256 times) public view returns(uint256, uint256, uint256[], address[], uint256[]){
        if(tabId == 0 || tabId >= _tables.length){
            return(tabId, times, new uint256[](1), new address[](0), new uint256[](0));
        }

        Table storage table = _tables[tabId];
        if(table.times == 0 || times > table.times){
            return(tabId, times, new uint256[](2), new address[](0), new uint256[](0));
        }
        Game storage game = table.gameList[times -1];
        uint256[] memory playerId = new uint256[](game.playerNum);
        address[] memory addr = new address[](game.playerNum);
        uint256[] memory rand = new uint256[](game.playerNum);

        for(uint256 i = 0; i < game.playerNum; i++){
            playerId[i] = i.add(1);
            addr[i] = game.playerList[i].addr;
            if(game.end){
                rand[i] = game.playerList[i].rand;
            }
        }

        return(tabId, times, playerId, addr, rand);
    }

    function addReferre(address addr, uint256 amount) internal returns(uint256){
        address referrerAddr;
        (referrerAddr, ,) = _relationService.getRelationship(addr);
        if(referrerAddr != address(0) && !Utils.isContract(referrerAddr)){
            uint256 fee = amount.mul(_referrefee).div(1000);
            _balance[referrerAddr] = _balance[referrerAddr].add(fee);
            return fee;
        }
        return 0;
    }

    function subReferre(address addr, uint256 amount) internal{
        address referrerAddr;
        (referrerAddr, ,) = _relationService.getRelationship(addr);
        if(referrerAddr != address(0) && !Utils.isContract(referrerAddr)){
            uint256 fee = amount.mul(_referrefee).div(1000);
            _balance[referrerAddr] = _balance[referrerAddr].sub(fee);
        }
    }

    function startLottery(uint tabId) public returns(bytes32, uint256){
        require(tabId >0 && tabId < _tables.length, "Out of range");

        Table storage table = _tables[tabId];
        require(table.times > 0, "No games");
        require(table.status == TableStatus.start, "The game has not started yet");

        Game storage game = table.gameList[table.times -1];

        require(game.amount > 0, "Game funds are zero");
        require(now >= game.startTimeStamp.add(table.intervalSeconds), "Time has not arrived");
        require(!game.end, "The game is over");

        game.lotteryTimeStamp = now;

        bool bMulPlayer = false;
        bytes32 seed;
        uint256 totalFee;
        for(uint256 i = 0; i < game.playerNum; i++){
            seed = keccak256(game.lotteryTimeStamp);
            seed = keccak256(seed, game.playerList[i].rand, game.playerList[i].addr);
            if(i > 0 && game.playerList[i].addr != game.playerList[i-1].addr){
                bMulPlayer = true;
            }
            totalFee = totalFee.add(addReferre(game.playerList[i].addr, table.single));
            _frozen[game.playerList[i].addr] = _frozen[game.playerList[i].addr].sub(table.single);
        }
        if(!bMulPlayer){
            if(!_isDebug && !Utils.isContract(game.playerList[0].addr)){
                _balance[game.playerList[0].addr] = _balance[game.playerList[0].addr].add(game.amount);
                subReferre(game.playerList[0].addr, game.amount);
            }
            table.status = TableStatus.stop;
            game.end = true;
            game.winnerId = 0;//无中奖者
            return(0, 0);
        }

        game.amount = game.amount.sub(totalFee);
        uint256 winner =  uint256(seed)%game.playerNum;
        table.status = TableStatus.stop;
        game.end = true;
        game.winnerId = winner.add(1);//索引+1

        address winnerAddr = game.playerList[winner].addr;
        PlayerShow storage playerShow  = _allPlayerShow[_playerIndex[winnerAddr]];
        for(i = 0; i < playerShow.num; i++){
            if(playerShow.detail[i].tabId == tabId && playerShow.detail[i].times == table.times){
                playerShow.detail[i].isWinner = true;
                break;
            }
        }

        _sendBonus(game.playerList[winner].addr, table, game.amount);

        return (seed, game.winnerId);
    }

    function detailOfPlayerShow(address addr, uint256 start, uint256 count) public view returns(uint256, uint256[], uint256[], uint256[], bool[]){
        uint256 end = _playerIndex[addr];
        if( end == 0){
            return(uint256(0), new uint256[](0), new uint256[](0), new uint256[](0), new bool[](0));
        }

        PlayerShow storage playerShow = _allPlayerShow[end];
        start = start.mul(count);
        if(start > playerShow.num){
            return(playerShow.num, new uint256[](0), new uint256[](0), new uint256[](0), new bool[](0));
        }else{
            end =  start <= playerShow.num && start.add(count) >= playerShow.num ? playerShow.num : start.add(count);
            count = end.sub(start);
            uint256[] memory tabId = new uint256[](count);
            uint256[] memory times = new uint256[](count);
            uint256[] memory playerNum = new uint256[](count);
            bool[] memory isWinner = new bool[](count);
            count = 0;
            for(; start < end; start++){
                tabId[count] = playerShow.detail[playerShow.num - start - 1].tabId;
                times[count] = playerShow.detail[playerShow.num - start - 1].times;
                playerNum[count] = playerShow.detail[playerShow.num - start - 1].playerNum;
                isWinner[count] = playerShow.detail[playerShow.num - start - 1].isWinner;
                count++;
            }

            return(playerShow.num, tabId, times, playerNum, isWinner);
        }
    }

    function destoryTable(uint256 tabId) public{
        require(tabId >0 && tabId < _tables.length, "Out of range");

        Table storage table = _tables[tabId];
        require(table.status == TableStatus.stop, "The game is in progress");
        require(table.status != TableStatus.destory, "The table has been destroyed");
        require(table.creator == msg.sender, "Only the owner can destroy");

        uint256 allFee = table.pledgeAmount.mul(_closefee).div(100);
        _frozen[msg.sender] = _frozen[msg.sender].sub(table.pledgeAmount);
        if(!_isDebug && !Utils.isContract(table.creator)){
            _balance[table.creator] = _balance[table.creator].add(table.pledgeAmount.sub(allFee));
        }

        table.status = TableStatus.destory;
        _allOutlay = _allOutlay.add(table.pledgeAmount);

        _sendBaseBonus(allFee);
    }
}
