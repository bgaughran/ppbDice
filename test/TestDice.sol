pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/dice.sol";

contract TestDice {

    // Truffle will send the contract one Ether after deploying the contract.
    uint public initialBalance = 1 ether;
//
//    function testConstructor() {
//
//        uint pwinExpected = 5000;
//        uint edgeExpected = 200; // edge percentage (10000 = 100%)
//        uint maxWinExpected = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
//        //        uint minBetExpected = 1; // min bet in finneys;
//        // Convert min bet from finneys to weis
//        uint minBetInWeiExpected = 1; //web3.toWei(minBetExpected, "finney");
//        uint maxInvestorsExpected = 5; //maximum number of investors
//        uint houseEdgeExpected = 50; //edge percentage (10000 = 100%)
//        uint divestFeeExpected = 50; //divest fee percentage (10000 = 100%)
//        uint emergencyWithdrawalRatioExpected = 90; //ratio percentage (100 = 100%)
//
//        Dice dice = new Dice(pwinExpected,
//            edgeExpected,
//            maxWinExpected,
//            minBetInWeiExpected,
//            maxInvestorsExpected,
//            houseEdgeExpected,
//            divestFeeExpected,
//            emergencyWithdrawalRatioExpected);
//
//        Assert.equal(pwinExpected, dice.pwin(), "pwin is incorrect");
//        Assert.equal(edgeExpected, dice.edge(), "edge is incorrect");
//        Assert.equal(maxWinExpected, dice.maxWin(), "maxWin is incorrect");
//        Assert.equal(minBetInWeiExpected, dice.minBet(), "minBet is incorrect");
//        Assert.equal(maxInvestorsExpected, dice.maxInvestors(), "maxInvestors is incorrect");
//        Assert.equal(houseEdgeExpected, dice.houseEdge(), "houseEdge is incorrect");
//        Assert.equal(divestFeeExpected, dice.divestFee(), "divestFee is incorrect");
//        Assert.equal(emergencyWithdrawalRatioExpected, dice.emergencyWithdrawalRatio(), "emergencyWithdrawalRatio is incorrect");
//    }
//
//    function testContractDefaults() {
//        //TODO: understsand why this is a valid constructor
//        Dice dice = Dice(DeployedAddresses.Dice());
//
//        uint pwinExpected = 5000;
//        uint edgeExpected = 200; // edge percentage (10000 = 100%)
//        uint maxWinExpected = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
////        uint minBetExpected = 1; // min bet in finneys;
//        // Convert min bet from finneys to weis
//        uint minBetInWeiExpected = 1; //web3.toWei(minBetExpected, "finney");
//        uint maxInvestorsExpected = 5; //maximum number of investors
//        uint houseEdgeExpected = 50; //edge percentage (10000 = 100%)
//        uint divestFeeExpected = 50; //divest fee percentage (10000 = 100%)
//        uint emergencyWithdrawalRatioExpected = 90; //ratio percentage (100 = 100%)
//
//        Assert.equal(pwinExpected, dice.pwin(), "pwin is incorrect");
//        Assert.equal(edgeExpected, dice.edge(), "edge is incorrect");
//        Assert.equal(maxWinExpected, dice.maxWin(), "maxWin is incorrect");
//        Assert.equal(minBetInWeiExpected, dice.minBet(), "minBet is incorrect");
//        Assert.equal(maxInvestorsExpected, dice.maxInvestors(), "maxInvestors is incorrect");
//        Assert.equal(houseEdgeExpected, dice.houseEdge(), "houseEdge is incorrect");
//        Assert.equal(divestFeeExpected, dice.divestFee(), "divestFee is incorrect");
//        Assert.equal(emergencyWithdrawalRatioExpected, dice.emergencyWithdrawalRatio(), "emergencyWithdrawalRatio is incorrect");
//    }

    function testBet() {

        address from;
        address to;

        Dice dice = Dice(DeployedAddresses.Dice());
        dice.send(initialBalance);

//    }
//    web3.eth.sendTransaction({ from: from, to: to, value: value, gas: 180000 }, function (err, address) {
//        dice.call({ from: from, to: to, value: value, gas: 180000 });
//        dice.call();
//        dice.call(from, to, value, 180000 );

//        need this to debug
//        console.log(dice);

//    }
    }

//    function () {
        // This will NOT be executed when Ether is sent. \o/
       // return initialBalance;
//    }
}