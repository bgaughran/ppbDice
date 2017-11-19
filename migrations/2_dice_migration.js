var Dice = artifacts.require("Dice");

var OraclizeI = artifacts.require("OraclizeI");
var OraclizeAddrResolverI = artifacts.require("OraclizeAddrResolverI");
var usingOraclize = artifacts.require("usingOraclize");


module.exports = function(deployer) {

    //Deploy and link all Oracalize contracts first
    deployer.deploy(OraclizeI);
    deployer.link(OraclizeI, Dice);

    deployer.deploy(OraclizeAddrResolverI);
    deployer.link(OraclizeAddrResolverI, Dice);

    deployer.deploy(usingOraclize);
    deployer.link(usingOraclize, Dice);

    deployer.deploy(Dice);
};
