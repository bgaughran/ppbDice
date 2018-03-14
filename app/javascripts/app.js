// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";
// import "../stylesheets/ppb.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import vdice_artifacts from '../../build/contracts/Dice.json'
// import metacoin_artifacts from '../../build/contracts/MetaCoin.json'

var Dice = contract(vdice_artifacts);
// MetaCoin is our usable abstraction, which we'll use through the code below.
// var MetaCoin = contract(metacoin_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;
var account2;
var numberOfBets;


window.App = {
  start: function() {
    var self = this;

    // Bootstrap the MetaCoin abstraction for Use.
    Dice.setProvider(web3.currentProvider);

      // Get the initial account balance so it can be displayed.

      web3.eth.getAccounts(function(err, accs) {
          if (err != null) {
              alert("There was an error fetching your accounts.");
              return;
          }

          if (accs.length == 0) {
              alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
              return;
          }

          accounts = accs;
          //pick the first account available - code only suitable for POC!
          account = accounts[0];
          account2 = accounts[1];

          self.refreshValues();
      });
    },

  setStatus: function(message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  },

  refreshValues: function() {
    printAllBalances();

    var self = this;
      var meta;

    Dice.deployed().then(function(instance) {
      meta = instance;
      return meta.numberOfBets.call();
    }).then(function(value) {
        var numberOfBets_element = document.getElementById("numberOfBets");
        console.log("numberOfBets="+value)
        numberOfBets_element.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting values; see log.");
    });

    Dice.deployed().then(function(instance) {
      meta = instance;
      return meta.winAmount.call();
    }).then(function(value) {
        console.log("winAmount="+value)
        var winAmount_element = document.getElementById("winAmount");
        winAmount_element.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting values; see log.");
    });

      Dice.deployed().then(function(instance) {
          meta = instance;
          return meta.totalWonOverall.call();
      }).then(function(value) {
          console.log("totalWonOverall="+value)
          var overallWinnings_element = document.getElementById("overallWinnings");
          overallWinnings_element.innerHTML = value.valueOf();
      }).catch(function(e) {
          console.log(e);
          self.setStatus("Error getting values; see log.");
      });

      var houseBalance_element = document.getElementById("houseBalance");
      houseBalance_element.innerHTML = web3.fromWei(web3.eth.getBalance(account));

      var playerBalance_element = document.getElementById("playerBalance");
      playerBalance_element.innerHTML = web3.fromWei(web3.eth.getBalance(account2));


      Dice.deployed().then(function(instance) {
          return instance.playerAddress.call();
      }).then(function(value) {
          console.log("playerAddress="+ value);
      }).catch(function(e) {
          console.log(e);
          self.setStatus("Error getting values; see log.");
      });

      Dice.deployed().then(function(instance) {
          return instance.houseAddressPublic.call();
      }).then(function(value) {
          console.log("houseAddressPublic="+ value);
      }).catch(function(e) {
          console.log(e);
          self.setStatus("Error getting values; see log.");
      });

      Dice.deployed().then(function(instance) {
          return instance.logPosition.call();
      }).then(function(value) {
          console.log("logPosition="+ value.toNumber());
      }).catch(function(e) {
          console.log(e);
          self.setStatus("Error getting values; see log.");
      });
  },

  roll: function() {
    var self = this;

    var amount = parseInt(document.getElementById("amount").value);
    // var receiver = document.getElementById("receiver").value;

    this.setStatus("Rolling the dice... (please wait)");
    // console.log("amount="+amount);

    var meta;
    Dice.deployed().then(function(instance) {
        meta = instance;
      // return meta.bet({value: 1, from:'0x627306090abab3a6e1400e9345bc60c78a8bef57', gas:3000000});
      return meta.bet({value: amount, from: account2, gas:2000000});
      // return meta.bet({value: 1, from: account2, gas:2000000});

    }).then(function() {

        Dice.deployed().then(function(instance) {
            return instance.oraclizeFee.call();
        }).then(function(value) {
            console.log("oraclizeFee="+ value.toNumber());
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error getting values; see log.");
        });

        Dice.deployed().then(function(instance) {
            return instance.logPosition.call();
        }).then(function(value) {
            console.log("logPosition="+ value.toNumber());
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error getting values; see log.");
        });

        Dice.deployed().then(function(instance) {
            meta = instance;

            var betResulted = meta.BetResulted({_from:web3.eth.coinbase},{fromBlock: 0, toBlock: 'latest'});
            betResulted.watch(function(error, result){
                if (!error) {
                    var amountWon = result.args.amountWon;
                    var numberRolled = result.args.numberRolled;
                    var contractBalance = result.args.contractBalance;

                    console.log("contractBalance after roll = "+ contractBalance.toNumber());

                    if (amountWon > 0) {
                        self.setStatus("Bet Won. Congrats! You rolled " + numberRolled + " and won " + amountWon);
                    } else {
                        self.setStatus("Bet Lost. You rolled " + numberRolled + ". Maybe next time?");
                    }
                    self.refreshValues();
                } else {
                    console.log("error="+error);
                    self.setStatus("Error encountered!");
                }
            });
            // betResulted.stopWatching();
        });

    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error encountered!");
    });
  }
};

function printAllBalances() {
    Dice.setProvider(web3.currentProvider);

    var i =0;
    web3.eth.accounts.forEach(
        function(e){
            console.log("  eth.accounts["+i+"]: " +  e + " \tbalance: " + web3.fromWei(web3.eth.getBalance(e), "ether") + " ether"); i++;
        }
    )
    var defaultAddress = '0x0000000000000000000000000000000000000000';
    console.log("  defaultAddress: " +  defaultAddress + " \tbalance: " + web3.fromWei(web3.eth.getBalance(defaultAddress), "ether") + " ether");

};

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:9545"));
  }

  App.start();
});
