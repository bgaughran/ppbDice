var Dice = artifacts.require("./Dice");

//var OraclizeI = artifacts.require("OraclizeI");
//var OraclizeAddrResolverI = artifacts.require("OraclizeAddrResolverI");
//var usingOraclize = artifacts.require("usingOraclize");

module.exports = function(deployer) {

    //Deploy and link all Oracalize contracts first
//    deployer.deploy(OraclizeI);
//    deployer.deploy(OraclizeAddrResolverI);
//    deployer.deploy(usingOraclize);

  var pwin = 5000; // probability of winning (10000 = 100%)
  var edge = 200; // edge percentage (10000 = 100%)
  var maxWin = 100; //max win (before edge is taken) as percentage of bankroll (10000 = 100%)
  var minBet = 1; // min bet in finneys
  var maxInvestors = 5; //maximum number of investors
  var houseEdge = 50; //edge percentage (10000 = 100%)
  var divestFee = 50; //divest fee percentage (10000 = 100%)
  var emergencyWithdrawalRatio = 90; //ratio percentage (100 = 100%)

  // Convert min bet from finneys to weis
//  var minBetInWei = web3.toWei(minBet, "finney");

//  deployer.deploy(Dice, pwin, edge, maxWin, minBetInWei,
//    maxInvestors, houseEdge, divestFee, emergencyWithdrawalRatio, {gas: 6000000});

  deployer.deploy(Dice, pwin, edge, maxWin, minBet,
    maxInvestors, houseEdge, divestFee, emergencyWithdrawalRatio, {gas: 6000000});

//    deployer.deploy(VDice, pwin, edge, minBetInWei, maxWin, minBet,
//    maxInvestors, houseEdge, divestFee, emergencyWithdrawalRatio, {gas: 6000000});

//    deployer.link(Dice, [OraclizeI, OraclizeAddrResolverI, usingOraclize]);
//    deployer.link(Dice, [usingOraclize]);


};
