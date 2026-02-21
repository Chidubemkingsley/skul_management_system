// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {SchoolToken, SchoolManagementSystem} from "../src/School_management.sol";

contract DeploySchoolSystem is Script {
    SchoolToken public schoolToken;
    SchoolManagementSystem public schoolManagementSystem;

    function setUp() public {}

    function run() public {
        // Load private key from .env
        uint256 deployerPrivateKey = 0x89f545254ca9cdfa2241d2ef7d6cfa9cbee2c7f4cbfaacc81222666bbe8ba313;
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy SchoolToken first with initial supply (e.g., 1,000,000 tokens)
        uint256 initialSupply = 1_000_000; // 1 million tokens
        schoolToken = new SchoolToken(initialSupply);
        
        // Set tuition fees for each level (in token wei units)
        // Example: 100 tokens for Level 100, 200 for Level 200, etc.
        uint256 fee100 = 100 * 10 ** 18; // 100 tokens (with 18 decimals)
        uint256 fee200 = 200 * 10 ** 18; // 200 tokens
        uint256 fee300 = 300 * 10 ** 18; // 300 tokens
        uint256 fee400 = 400 * 10 ** 18; // 400 tokens
        
        // Deploy SchoolManagementSystem with token address and tuition fees
        schoolManagementSystem = new SchoolManagementSystem(
            address(schoolToken),
            fee100,
            fee200,
            fee300,
            fee400
        );

        vm.stopBroadcast();
    }
}