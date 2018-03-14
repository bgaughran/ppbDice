pragma solidity ^0.4.18;
import "./usingOraclize.sol";

contract Dice is usingOraclize {

    uint public pwin = 5000; //probability of winning (10000 = 100%)
    uint public edge = 200; //edge percentage (10000 = 100%); 200=5%
    uint public maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
    uint public minBet = 1 finney;
    uint public maxInvestors = 5; //maximum number of investors
    uint public houseEdge = 5000; //edge percentage (10000 = 100%)
    uint public divestFee = 50; //divest fee percentage (10000 = 100%)
    uint public emergencyWithdrawalRatio = 90; //ratio percentage (100 = 100%)

    uint safeGas = 25000;
    uint constant ORACLIZE_GAS_LIMIT = 175000;

    uint public logPosition = 0;
    uint public investorsProfit = 0;
    uint public investorsLoses = 0;

    uint public numberOfBets = 0;

    /*
  BEFORE CHANGES...
  develop:testrpc   Transaction: 0x70a02d0357e2075a16f42c2d007db536ca0aa90ecadb32bf8e09850136c8b016 +0ms
  develop:testrpc   Gas usage: 150000 +0ms
  develop:testrpc   Block Number: 76 +0ms
  develop:testrpc   Block Time: Sun Feb 18 2018 21:42:08 GMT+0000 (GMT) +0ms
  develop:testrpc   Runtime Error: out of gas +0ms

  AFTER CHANGES....
  develop:testrpc   Transaction: 0x43b73bdcd5dda6b26e0c67df8adc5119f26576c3e4f4e47b4e89d90e46d1408e +0ms
  develop:testrpc   Gas usage: 204403 +0ms
  develop:testrpc   Block Number: 82 +0ms
  develop:testrpc   Block Time: Sun Feb 18 2018 21:45:03 GMT+0000 (GMT) +1ms
  develop:testrpc  +0ms

  develop:testrpc  +6ms
  develop:testrpc   Transaction: 0xe14869faa4131e739318e1b38036147f0da75a4924284e6339d0bc158c7bd395 +1ms
  develop:testrpc   Gas usage: 156320 +0ms
  develop:testrpc   Block Number: 83 +0ms
  develop:testrpc   Block Time: Sun Feb 18 2018 21:45:26 GMT+0000 (GMT) +0ms
  develop:testrpc  +0ms
    */


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

    uint public invested = 100000;

    address owner;
    address houseAddress;
    bool public isStopped;

    WithdrawalProposal public proposedWithdrawal;

    mapping (bytes32 => Bet) bets;
    bytes32[] betsKeys;

    uint public amountWagered = 0;
    bool profitDistributed;

    event BetResulted(address playerAddress, uint numberRolled, uint amountWon, uint contractBalance);
    event EmergencyWithdrawalProposed();
    event EmergencyWithdrawalFailed(address withdrawalAddress);
    event EmergencyWithdrawalSucceeded(address withdrawalAddress, uint amountWithdrawn);
    event FailedSend(address receiver, uint amount);
    event ValueIsTooBig();

    //BG - This is the constructor whose code is
    //BG - run only when the contract is created.
    function Dice(uint pwinInitial,
                  uint edgeInitial,
                  uint maxWinInitial,
                  uint minBetInitial,
                  uint maxInvestorsInitial,
                  uint houseEdgeInitial,
                  uint divestFeeInitial,
                  uint emergencyWithdrawalRatioInitial
                  ) {

        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
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
        logPosition = 11;
        if (msg.sender != oraclize_cbAddress()) throw;
        _;
    }

    modifier onlyMoreThanZero {
        if (msg.value == 0) throw;
        _;
    }

    modifier onlyIfNotProcessed(bytes32 myid) {
        logPosition = 21;
        Bet thisBet = bets[myid];
        if (thisBet.numberRolled > 0) throw;
        _;
    }

    modifier onlyIfValidRoll(bytes32 myid, string result) {
        logPosition = 31;
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
        logPosition = 41;

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
            logPosition = 9551;
            ValueIsTooBig();
            return;
        }

        logPosition = 9552;

        //addr.transfer(value);

        logPosition = 9553;

//        if (!(addr.call.gas(safeGas).value(value)())) {
//            FailedSend(addr, value);
//            logPosition = 9553;
//
//          if (addr != houseAddress) {
//                //Forward to house address all change
//                logPosition = 9554;
//
//                if (!(houseAddress.call.gas(safeGas).value(value)())) {
//                    logPosition = 9555;
//                    FailedSend(houseAddress, value);
//                }
//          }
//        }
    }

    // SECTION II: BET & BET PROCESSING

    function() payable {
        bet();
    }

    event BetEvent(
        address indexed _from,
        uint _value,
        uint _oraclizeFee,
        uint _edge,
        uint _pwin,
        uint _maxWin,
        uint _bankRoll,
        uint _minBet
    );

    uint public oraclizeFee;
    function bet() payable onlyIfNotStopped onlyMoreThanZero {
        logPosition = 1;

        oraclizeFee = OraclizeI(OAR.getAddress()).getPrice("URL", ORACLIZE_GAS_LIMIT + safeGas);
//        Why come back as 0?
//        What is getPrice? Am I using return value correctly?
//        Understand concept of gas
//        Look at previous Gitter replies

        uint betValue = msg.value - oraclizeFee;

        BetEvent(msg.sender, msg.value, oraclizeFee, edge, pwin, maxWin, getBankroll(), minBet);

        logPosition = 2;

        if ((((betValue * ((10000 - edge) - pwin)) / pwin ) <= (maxWin * getBankroll()) / 10000) && (betValue >= minBet)) {

            logPosition = 3;

            // encrypted arg: '\n{"jsonrpc":2.0,"method":"generateSignedIntegers","params":{"apiKey":"YOUR_API_KEY","n":1,"min":1,"max":10000},"id":1}'
//            bytes32 myid = oraclize_query(
//                "URL",
//                "json(https://api.random.org/json-rpc/1/invoke).result.random.data.0","BBX1PCQ9134839wTz10OWxXCaZaGk92yF6TES8xA+8IC7xNBlJq5AL0uW3rev7IoApA5DMFmCfKGikjnNbNglKKvwjENYPB8TBJN9tDgdcYNxdWnsYARKMqmjrJKYbBAiws+UU6HrJXUWirO+dBSSJbmjIg+9vmBjSq8KveiBzSGmuQhu7/hSg5rSsSP/r+MhR/Q5ECrOHi+CkP/qdSUTA/QhCCjdzFu+7t3Hs7NU34a+l7JdvDlvD8hoNxyKooMDYNbUA8/eFmPv2d538FN6KJQp+RKr4w4VtAMHdejrLM=",
//                ORACLIZE_GAS_LIMIT + safeGas
//            );

//            bytes32 myid =
//            oraclize_query(
//                "nested",
//                "[URL] ['json(https://api.random.org/json-rpc/1/invoke).result.random.data.0', '\\n{\"jsonrpc\":\"2.0\",\"method\":\"generateSignedIntegers\",\"params\":{\"apiKey\":,\"n\":1,\"min\":1,\"max\":10000${[identity] \"}\"},\"id\":1${[identity] \"}\"}']",
//                "[URL] ['json(https://api.random.org/json-rpc/1/invoke).result.random.data.0', '\\n{\"jsonrpc\":\"2.0\",\"method\":\"generateSignedIntegers\",\"params\":{\"apiKey\":,\"n\":1,\"min\":1,\"max\":10000,\"replacement\":true,\"base\":10},\"id\":16790\"}']",

            //                ORACLIZE_GAS_LIMIT + safeGas
//            );

            //         8ae1f7a1-67b0-4409-a515-869b3e1f7e7a
            bytes32 myid =
            oraclize_query(
                "nested",
                "[URL] ['json(https://api.random.org/json-rpc/1/invoke).result.random.data.0', '\\n{\"jsonrpc\":\"2.0\",\"method\":\"generateSignedIntegers\",\"params\":{\"apiKey\":\"8ae1f7a1-67b0-4409-a515-869b3e1f7e7a\",\"n\":1,\"min\":1,\"max\":10000,\"replacement\":true,\"base\":10},\"id\":16790}']",
                ORACLIZE_GAS_LIMIT + safeGas
            );

            bets[myid] = Bet(msg.sender, betValue, 0);
            betsKeys.push(myid);

            logPosition = 4;

        }
        else {
            logPosition = 9999;
            throw;
        }
    }

    uint public numberRolled;
    function __callback (bytes32 myid, string result, bytes proof)
//HELPS MINIMISE OUT OF GAS ON CALLBACK!!!!
 //        onlyOraclize
 //        onlyIfNotProcessed(myid)
 //        onlyIfValidRoll(myid, result)
 //        onlyIfBetSizeIsStillCorrect(myid)
    {

        logPosition = 5;

        Bet thisBet = bets[myid];
        numberRolled = parseInt(result);
        bets[myid].numberRolled = numberRolled;
        isWinningBet(thisBet, numberRolled);
        isLosingBet(thisBet, numberRolled);
        amountWagered += thisBet.amountBetted;
        delete profitDistributed;

        numberOfBets += 1; //bet counter

    }

    uint public winAmount;
    uint public totalWonOverall;
    address public playerAddress;
    address public houseAddressPublic;

    function isWinningBet(Bet thisBet, uint numberRolled) private onlyWinningBets(numberRolled) {
        logPosition = 5551;

        winAmount = (thisBet.amountBetted * (10000 - edge)) / pwin;
        totalWonOverall+= winAmount;

        BetResulted(thisBet.playerAddress, numberRolled, winAmount, this.balance);
//        safeSend(thisBet.playerAddress, winAmount);
        playerAddress = thisBet.playerAddress;

        investorsLoses += (winAmount - thisBet.amountBetted);
    }

    function isLosingBet(Bet thisBet, uint numberRolled) private onlyLosingBets(numberRolled) {
        logPosition = 5552;
        BetResulted(thisBet.playerAddress, numberRolled, 0, this.balance);
//        safeSend(thisBet.playerAddress, 1);
        investorsProfit += (thisBet.amountBetted - 1)*(10000 - houseEdge)/10000;
        uint houseProfit = (thisBet.amountBetted - 1)*(houseEdge)/10000;
        safeSend(houseAddress, houseProfit);
        houseAddressPublic = houseAddress;
    }


}
