pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/dice.sol";

contract TestDice {
    function testConstructor() {
        Dice dice = Dice(DeployedAddresses.Dice());

        uint pwinExpected = 5000;
        uint edgeExpected = 200; // edge percentage (10000 = 100%)
        uint maxWinExpected = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
        uint minBetExpected = 1; // min bet in finneys;
        // Convert min bet from finneys to weis
        uint minBetInWeiExpected = 1; //web3.toWei(minBet, "finney");
        uint maxInvestorsExpected = 5; //maximum number of investors
        uint houseEdgeExpected = 50; //edge percentage (10000 = 100%)
        uint divestFeeExpected = 50; //divest fee percentage (10000 = 100%)
        uint emergencyWithdrawalRatioExpected = 90; //ratio percentage (100 = 100%)

        Assert.equal(pwinExpected, dice.pwin(), "pwin is incorrect");
        Assert.equal(edgeExpected, dice.edge(), "edge is incorrect");
        Assert.equal(maxWinExpected, dice.maxWin(), "maxWin is incorrect");
        Assert.equal(minBetInWeiExpected, dice.minBet(), "minBet is incorrect");
        Assert.equal(maxInvestorsExpected, dice.maxInvestors(), "maxInvestors is incorrect");
        Assert.equal(houseEdgeExpected, dice.houseEdge(), "houseEdge is incorrect");
        Assert.equal(divestFeeExpected, dice.divestFee(), "divestFee is incorrect");
        Assert.equal(emergencyWithdrawalRatioExpected, dice.emergencyWithdrawalRatio(), "emergencyWithdrawalRatio is incorrect");
    }

    function testBet() {
        uint  value = 1 ether;
        address from;
        address to;

        Dice dice = Dice(DeployedAddresses.Dice());
//        dice.call({ from: from, to: to, value: value, gas: 180000 });
        dice.call();
//        dice.call(from, to, value, 180000 );

//        need this to debug
//        console.log(dice);

//        from view-source:https://www.vdice.io/Scripts/vdice.js
//        web3.eth.sendTransaction({ from: from, to: to, value: value, gas: 180000 }, function (err, address) {
//    }
    }
}