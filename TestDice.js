var Dice = artifacts.require("./contracts/Dice");

//allows the Javascript to be called externally
module.exports = function(callback) {

    var meta;
    Dice.deployed().then(function(instance) {
        // Print the deployed version of Dice.
        console.log(instance);
        meta = instance;
//        return meta.send({ from: from, to: to, value: web3.toWei(1, "ether"), gas: 180000 }).then(function(result) {
//        return meta.send(web3.toWei(1, "ether")).then(function(result) {
               // If this callback is called, the transaction was successfully processed.
//               alert("Transaction successful!")
//               console.log("Transaction successful!")
//             }).catch(function(e) {
               // There was an error! Handle it.
//               console.log("Transaction UNSuccessful!")
//         })
    })


//            web3.eth.sendTransaction({ from: from, to: to, value: value, gas: 180000 }, function (err, address) {

}
