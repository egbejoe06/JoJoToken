// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {NFTStore} from "../src/Nft.sol";

contract DeployScript is Script {
    function run() external returns (NFTStore) {
        // Begin recording transactions for deployment
        vm.startBroadcast();

        // Address of the payment token (JonathanToken)
        address paymentTokenAddress = 0x43d5F1999D228c8aB46D5Ae29c1C2594534c131F;

        // Deploy the NFTStore contract
        NFTStore nftstore = new NFTStore(paymentTokenAddress);

        // Stop recording transactions
        vm.stopBroadcast();

        // Return the deployed NFTStore contract instance
        return nftstore;
    }
}
