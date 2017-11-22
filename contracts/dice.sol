pragma solidity ^0.4.17;
import "./usingOraclize.sol";

contract Dice is usingOraclize {

    uint public pwin = 5000; //probability of winning (10000 = 100%)
    uint public edge = 200; //edge percentage (10000 = 100%)
    uint public maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    uint public minBet = 1 finney;
    uint public maxInvestors = 5; //maximum number of investors
    uint public houseEdge = 50; //edge percentage (10000 = 100%)
    uint public divestFee = 50; //divest fee percentage (10000 = 100%)
    uint public emergencyWithdrawalRatio = 90; //ratio percentage (100 = 100%)

    uint safeGas = 25000;
    uint constant ORACLIZE_GAS_LIMIT = 125000;
    uint constant INVALID_BET_MARKER = 99999;
    uint constant EMERGENCY_TIMEOUT = 7 days;

    struct Investor {
        address investorAddress;
        uint amountInvested;
        bool votedForEmergencyWithdrawal;
    }

    struct Bet {
        address playerAddress;
        uint amountBetted;
        uint numberRolled;
    }

    struct WithdrawalProposal {
        address toAddress;
        uint atTime;
    }

    //Starting at 1
    mapping(address => uint) public investorIDs;
    mapping(uint => Investor) public investors;
    uint public numInvestors = 0;

    uint public invested = 0;

    address owner;
    address houseAddress;
    bool public isStopped;

    WithdrawalProposal public proposedWithdrawal;

    mapping (bytes32 => Bet) bets;
    bytes32[] betsKeys;

    uint public amountWagered = 0;
    uint public investorsProfit = 0;
    uint public investorsLoses = 0;
    bool profitDistributed;

    event BetWon(address playerAddress, uint numberRolled, uint amountWon);
    event BetLost(address playerAddress, uint numberRolled);
    event EmergencyWithdrawalProposed();
    event EmergencyWithdrawalFailed(address withdrawalAddress);
    event EmergencyWithdrawalSucceeded(address withdrawalAddress, uint amountWithdrawn);
    event FailedSend(address receiver, uint amount);
    event ValueIsTooBig();

    function Dice(uint pwinInitial,
                  uint edgeInitial,
                  uint maxWinInitial,
                  uint minBetInitial,
                  uint maxInvestorsInitial,
                  uint houseEdgeInitial,
                  uint divestFeeInitial,
                  uint emergencyWithdrawalRatioInitial
                  ) {

        OAR = OraclizeAddrResolverI(0xDd506A9a6F420d27875dEa56B0830c3F01904ff9);
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);

        pwin = pwinInitial;
        edge = edgeInitial;
        maxWin = maxWinInitial;
        minBet = minBetInitial;
        maxInvestors = maxInvestorsInitial;
        houseEdge = houseEdgeInitial;
        divestFee = divestFeeInitial;
        emergencyWithdrawalRatio = emergencyWithdrawalRatioInitial;
        owner = msg.sender;
        houseAddress = msg.sender;
    }

    //SECTION I: MODIFIERS AND HELPER FUNCTIONS

    //MODIFIERS

    modifier onlyIfNotStopped {
        if (isStopped) throw;
        _;
    }

    modifier onlyOraclize {
        if (msg.sender != oraclize_cbAddress()) throw;
        _;
    }

    modifier onlyMoreThanZero {
        if (msg.value == 0) throw;
        _;
    }

    modifier onlyIfNotProcessed(bytes32 myid) {
        Bet thisBet = bets[myid];
        if (thisBet.numberRolled > 0) throw;
        _;
    }

    modifier onlyIfValidRoll(bytes32 myid, string result) {
        Bet thisBet = bets[myid];
        uint numberRolled = parseInt(result);
        if ((numberRolled < 1 || numberRolled > 10000) && thisBet.numberRolled == 0) {
            bets[myid].numberRolled = INVALID_BET_MARKER;
            safeSend(thisBet.playerAddress, thisBet.amountBetted);
            return;
        }
        _;
    }


    modifier onlyIfBetSizeIsStillCorrect(bytes32 myid) {
        Bet thisBet = bets[myid];
        if ((((thisBet.amountBetted * ((10000 - edge) - pwin)) / pwin ) <= (maxWin * getBankroll()) / 10000)) {
            _;
        }
        else {
            bets[myid].numberRolled = INVALID_BET_MARKER;
            safeSend(thisBet.playerAddress, thisBet.amountBetted);
            return;
        }
    }

    modifier onlyWinningBets(uint numberRolled) {
        if (numberRolled - 1 < pwin) {
            _;
        }
    }

    modifier onlyLosingBets(uint numberRolled) {
        if (numberRolled - 1 >= pwin) {
            _;
        }
    }

    //CONSTANT HELPER FUNCTIONS

    function getBankroll() constant returns(uint) {
        return invested + investorsProfit - investorsLoses;
    }

    function getMinInvestment() constant returns(uint) {
        if (numInvestors == maxInvestors) {
            uint investorID = searchSmallestInvestor();
            return getBalance(investors[investorID].investorAddress);
        }
        else {
            return 0;
        }
    }

    function getLosesShare(address currentInvestor) constant returns (uint) {
        return investors[investorIDs[currentInvestor]].amountInvested * (investorsLoses) / invested;
    }

    function getProfitShare(address currentInvestor) constant returns (uint) {
        return investors[investorIDs[currentInvestor]].amountInvested * (investorsProfit) / invested;
    }

    function getBalance(address currentInvestor) constant returns (uint) {
        return investors[investorIDs[currentInvestor]].amountInvested + getProfitShare(currentInvestor) - getLosesShare(currentInvestor);
    }

    function searchSmallestInvestor() constant returns(uint) {
        uint investorID = 1;
        for (uint i = 1; i <= numInvestors; i++) {
            if (getBalance(investors[i].investorAddress) < getBalance(investors[investorID].investorAddress)) {
                investorID = i;
            }
        }

        return investorID;
    }

    // PRIVATE HELPERS FUNCTION

    function safeSend(address addr, uint value) private {
        if (this.balance < value) {
            ValueIsTooBig();
            return;
        }

        if (!(addr.call.gas(safeGas).value(value)())) {
            FailedSend(addr, value);
            if (addr != houseAddress) {
                //Forward to house address all change
                if (!(houseAddress.call.gas(safeGas).value(value)())) FailedSend(houseAddress, value);
            }
        }
    }

    // SECTION II: BET & BET PROCESSING

    function() {
        bet();
    }

    function bet() onlyIfNotStopped onlyMoreThanZero {
        uint oraclizeFee = OraclizeI(OAR.getAddress()).getPrice("URL", ORACLIZE_GAS_LIMIT + safeGas);
        uint betValue = msg.value - oraclizeFee;
        if ((((betValue * ((10000 - edge) - pwin)) / pwin ) <= (maxWin * getBankroll()) / 10000) && (betValue >= minBet)) {
            // encrypted arg: '\n{"jsonrpc":2.0,"method":"generateSignedIntegers","params":{"apiKey":"YOUR_API_KEY","n":1,"min":1,"max":10000},"id":1}'
            bytes32 myid = oraclize_query("URL", "json(https://api.random.org/json-rpc/1/invoke).result.random.data.0","BBX1PCQ9134839wTz10OWxXCaZaGk92yF6TES8xA+8IC7xNBlJq5AL0uW3rev7IoApA5DMFmCfKGikjnNbNglKKvwjENYPB8TBJN9tDgdcYNxdWnsYARKMqmjrJKYbBAiws+UU6HrJXUWirO+dBSSJbmjIg+9vmBjSq8KveiBzSGmuQhu7/hSg5rSsSP/r+MhR/Q5ECrOHi+CkP/qdSUTA/QhCCjdzFu+7t3Hs7NU34a+l7JdvDlvD8hoNxyKooMDYNbUA8/eFmPv2d538FN6KJQp+RKr4w4VtAMHdejrLM=", ORACLIZE_GAS_LIMIT + safeGas);
            bets[myid] = Bet(msg.sender, betValue, 0);
            betsKeys.push(myid);
        }
        else {
            throw;
        }
    }

    function __callback (bytes32 myid, string result, bytes proof)
        onlyOraclize
        onlyIfNotProcessed(myid)
        onlyIfValidRoll(myid, result)
        onlyIfBetSizeIsStillCorrect(myid)  {

        Bet thisBet = bets[myid];
        uint numberRolled = parseInt(result);
        bets[myid].numberRolled = numberRolled;
        isWinningBet(thisBet, numberRolled);
        isLosingBet(thisBet, numberRolled);
        amountWagered += thisBet.amountBetted;
        delete profitDistributed;
    }

    function isWinningBet(Bet thisBet, uint numberRolled) private onlyWinningBets(numberRolled) {
        uint winAmount = (thisBet.amountBetted * (10000 - edge)) / pwin;
        BetWon(thisBet.playerAddress, numberRolled, winAmount);
        safeSend(thisBet.playerAddress, winAmount);
        investorsLoses += (winAmount - thisBet.amountBetted);
    }

    function isLosingBet(Bet thisBet, uint numberRolled) private onlyLosingBets(numberRolled) {
        BetLost(thisBet.playerAddress, numberRolled);
        safeSend(thisBet.playerAddress, 1);
        investorsProfit += (thisBet.amountBetted - 1)*(10000 - houseEdge)/10000;
        uint houseProfit = (thisBet.amountBetted - 1)*(houseEdge)/10000;
        safeSend(houseAddress, houseProfit);
    }


}
