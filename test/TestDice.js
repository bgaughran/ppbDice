var Dice = artifacts.require("./contracts/Dice");

//allows the Javascript to be called externally
module.exports = function(callback) {

    var meta;
    Dice.deployed().then(function(instance) {
        // Print the deployed version of Dice.
        // console.log(instance);
        meta = instance;

        var event = Dice.deployed().BetEvent();

// from view-source:https://www.vdice.io/Scripts/vdice.js
// if (typeof web3 !== 'undefined') {
//     web3 = new Web3(web3.currentProvider);
// } else {
//     web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
// }
// to=web3.toWei(1, "ether")
// web3.eth.sendTransaction({ from: from, to: to, value: value, gas: 180000 }, function (err, address) {

        // watch for changes
        event.watch(function(error, result){
            // result will contain various information
            // including the argumets given to the `BetEvent`
            // call.
            if (!error)
                console.log(result);
        });

        // // Or pass a callback to start watching immediately
        // var event = meta.BetEvent(function(error, result) {
        //     if (!error)
        //         console.log(result);
        // });

        // return meta.send({ from: from, to: to, value: web3.toWei(1, "ether"), gas: 180000 }).then(function(result) {
       return meta.send(web3.toWei(1, "ether")).then(function(result) {
               // If this callback is called, the transaction was successfully processed.
              alert("Transaction successful!")
              console.log("Transaction successful!")
            }).catch(function(e) {
               // There was an error! Handle it.
              console.log("Transaction UNSuccessful!")
        })
    })



}
