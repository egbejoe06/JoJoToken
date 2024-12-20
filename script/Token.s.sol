// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {JonathanToken} from "../src/Token.sol";

contract DeployScript is Script {
    function run() external returns (JonathanToken) {
        // Begin recording transactions for deployment
        vm.startBroadcast();

        // Deploy the contract
        JonathanToken jonathantoken = new JonathanToken();

        // Stop recording transactions
        vm.stopBroadcast();

        // Return the deployed token contract instance
        return jonathantoken;
    }
}
