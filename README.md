# ppbDice-Contract-Code

#   Environment set up:

Install...
truffle
ethereum bridge (clone from Github(https://github.com/oraclize/ethereum-bridge), then run 'npm install' in unzipped folder

(Optional Install)
Solidity intellij plugIn
Solhint intellij plugIn (depends on installing 'solhint JS' file  in '/usr/local/lib/node_modules/solhint/solhint.js')

To deploy...
testrpc --mnemonic "case meadow shuffle purpose renew echo before correct rate artist seed net" -a 50

cd ~/IdeaProjects/ppbDice/ethereum-bridge-master
node bridge -a 49

cd ~/IdeaProjects/ppbDice/
rm -rf build/contracts

truffle compile --all
truffle migrate --reset

To test...
truffle test

To run....
truffle exec TestDice.js

To debug.....
truffle debug 0x48689dd9172ac7a0ccc2496ecd2245d5a5071a7bb64fd28cdf880444a4ac76d5
