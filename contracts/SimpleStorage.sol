pragma solidity ^0.4.17;

//Test contract from http://truffleframework.com/tutorials/debugging-a-smart-contract to
//demo the use of Truffle debugger
contract SimpleStorage {
    uint myVariable;

    function set(uint x) public {
        myVariable = x;
    }

    function get() constant public returns (uint) {
        return myVariable;
    }
}