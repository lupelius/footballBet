 solidity ^0.4.2;

import './strings.sol';
import './safemath.sol';

contract FootballBet {
    using strings for *;

    enum Result { HOMETEAMWIN, AWAYTEAMWIN, DRAW, PENDING, UNKNOWN }

    struct Game {
        string gameId;
        string date;
        string status;
        string homeTeam;
        string awayTeam;
        uint homeTeamGoals;
        uint awayTeamGoals;
        Result result;
        uint receivedGoalMsgs;
    }

    struct Bet {
        uint stake;
        uint win;
        address sender;
    }

    struct Request {
        bool initialized;
        bool processed;
        string key;
    }

    mapping(uint8 => Bet[]) bets;
    mapping(uint256 => uint) betSums;

    mapping(address => uint) pendingWithdrawals;

    Game game;
    
    event Info(string message);

    event BetEvent(uint stake, uint win, address sender);

    constructor() {
        
    }

    function queryFootballData(string gameId, string key, uint gas) public {
        //use oraclize to make a request to get the game results from an api, 
        //instead of static results
        game.status = 'FINISHED';
        game.homeTeam = 'Barcelona';
        game.awayTeam = 'Real Madrid';
        game.homeTeamGoals = 1;
        game.awayTeamGoals = 0;
        game.result = determineResult(game.homeTeamGoals, game.awayTeamGoals);
        Info(gameToString());
    }
    
    function gameToString() constant returns (string) {
        string memory result = 'unknown';
        if (game.result == Result.HOMETEAMWIN) { result = 'homeTeamWin'; }
        else if (game.result == Result.AWAYTEAMWIN) { result = 'awayTeamWin'; }
        else if (game.result == Result.DRAW) { result = 'draw'; }

        strings.slice[] memory parts = new strings.slice[](8);
        parts[0] = game.gameId.toSlice();
        parts[1] = game.date.toSlice();
        parts[2] = game.status.toSlice();
        parts[3] = game.homeTeam.toSlice();
        parts[4] = game.awayTeam.toSlice();
        parts[5] = uint2str(game.homeTeamGoals).toSlice();
        parts[6] = uint2str(game.awayTeamGoals).toSlice();
        parts[7] = result.toSlice();
        return ', '.toSlice().join(parts);
    }

    function createGame(string gameId) public payable {
        game = Game(gameId, '0', 'UNKNOWN', '', '', 0, 0, Result.UNKNOWN, 0);
        queryFootballData(game.gameId, 'JSON_FIXTURE', 2200000);
    }

    function evaluate() public {
        queryFootballData(game.gameId, 'JSON_RESULT', 400000);
    }

    function determineResult(uint homeTeam, uint awayTeam) constant returns (Result) {
        if (homeTeam > awayTeam) { return Result.HOMETEAMWIN; }
        if (homeTeam == awayTeam) { return Result.DRAW; }
        return Result.AWAYTEAMWIN;
    }

    function placeBet(uint8 _bet) public payable {
        Bet memory b = Bet(msg.value, 0, msg.sender);
        bets[_bet].push(b);
        betSums[_bet] = SafeMath.add(betSums[_bet], msg.value);
        BetEvent(b.stake, b.win, b.sender);
    }

    function setWinners() {
        uint256 loosingStake = 0;

        if (game.result != Result.HOMETEAMWIN) {
            loosingStake = SafeMath.add(loosingStake, betSums[uint8(Result.HOMETEAMWIN)]);
        }

        if (game.result != Result.AWAYTEAMWIN) {
            loosingStake = SafeMath.add(loosingStake, betSums[uint8(Result.AWAYTEAMWIN)]);
        }

        if (game.result != Result.DRAW) {
            loosingStake = SafeMath.add(loosingStake, betSums[uint8(Result.DRAW)]);
        }

        // determine the win per wei
        uint winPerWei = SafeMath.div(loosingStake, betSums[uint8(game.result)]);

        for (uint i=0; i<bets[uint8(game.result)].length; i++) {
            Bet storage b = bets[uint8(game.result)][i];
            b.win = winPerWei * b.stake;
            BetEvent(b.stake, b.win, b.sender);
            pendingWithdrawals[b.sender] = SafeMath.add(b.stake, b.win);
        }
    }

    function withdraw() returns (bool) {
        uint amount = pendingWithdrawals[msg.sender];
        //setting the transaction to be done first for safety
        pendingWithdrawals[msg.sender] = 0;
        //use transfer method instead of send
        msg.sender.transfer(amount);

    }

    function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    //helper function to translate uint type to string
    function uint2str(uint i) internal returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

}
