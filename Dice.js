var Dice = artifacts.require("./contracts/Dice");

//allows the Javascript to be called externally
module.exports = function(callback) {

    // Print the deployed version of Dice.
    // Note that getting the deployed version requires a promise, hence the .then.
    Dice.deployed().then(function(instance) {
      console.log(instance);
    });

}