// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract JonathanToken is ERC20 {
    uint256 public baseDailyReward = 200 * 10**decimals(); // Daily login reward (20 tokens)
    uint256 public giftCodeReward = 10000 * 10**decimals(); // Gift code reward (1000 tokens)
    uint256 public tokenToEthRate = 10**decimals() / 100000; // 0.00001 ETH per token
    mapping(address => uint256) public lastClaimed; // Track last claim timestamp for daily login
    mapping(string => bool) public usedGiftCodes; // Track used gift codes
    mapping(string => bool) public validGiftCodes; // Store valid gift codes
    mapping(address => bool) public admins; // Track logged-in admins

    uint256 public preSaleRate = 10**decimals() / 50000;

    address[] public tokenHolders; // Track token holders
    mapping(address => bool) private isHolder; // Check if address is already a token holder

    // Hashed username and password for authentication
    bytes32 private constant USERNAME_HASH = keccak256(abi.encodePacked("Egbe"));
    bytes32 private constant PASSWORD_HASH = keccak256(abi.encodePacked("something12"));

    constructor() ERC20("Jonathan", "JoJo") {
        _mint(msg.sender, 10000 * 10**decimals()); // Initial supply to deployer
        admins[msg.sender] = true; // Contract deployer is an admin by default
    }

    // --- Admin Login ---
    function login(string memory username, string memory password) public {
        require(
            keccak256(abi.encodePacked(username)) == USERNAME_HASH &&
            keccak256(abi.encodePacked(password)) == PASSWORD_HASH,
            "Invalid username or password"
        );
        admins[msg.sender] = true; // Grant admin access to the sender
    }

    // --- Admin Logout ---
    function logout() public {
        require(admins[msg.sender], "You are not logged in as an admin");
        admins[msg.sender] = false;
    }

    // --- Admin-Only Modifier ---
    modifier onlyAdmin() {
        require(admins[msg.sender], "You do not have admin access");
        _;
    }

    // --- Daily Login ---
    function claimDailyLoginReward() public {
        uint256 currentDay = block.timestamp / 1 days;

        require(lastClaimed[msg.sender] / 1 days != currentDay, "Already claimed for today");

        _mint(msg.sender, baseDailyReward);
        lastClaimed[msg.sender] = block.timestamp;
    }

    // --- Gift Code ---
    function redeemGiftCode(string memory code) public {
        require(validGiftCodes[code], "Invalid gift code");
        require(!usedGiftCodes[code], "Gift code already used");
        
        usedGiftCodes[code] = true; // Mark code as used
        _mint(msg.sender, giftCodeReward);
    }

    function addGiftCode(string memory code) public onlyAdmin {
        require(!validGiftCodes[code], "Gift code already exists");
        validGiftCodes[code] = true; // Add the code as valid
    }

        function buyTokens() public payable {
        require(msg.value > 0, "Must send ETH to buy tokens");

        uint256 tokenAmount = msg.value * 10**decimals() / preSaleRate;
        _mint(msg.sender, tokenAmount);

        // Add to tokenHolders if not already present
        if (!isHolder[msg.sender]) {
            tokenHolders.push(msg.sender);
            isHolder[msg.sender] = true;
        }
    }

    // --- Leaderboard ---
    function getLeaderboard() public view returns (address[] memory, uint256[] memory) {
        uint256 length = tokenHolders.length;
        address[] memory holders = tokenHolders;
        uint256[] memory balances = new uint256[](length);

        // Collect balances
        for (uint256 i = 0; i < length; i++) {
            balances[i] = balanceOf(holders[i]);
        }

        // Sort in descending order (Bubble Sort for simplicity, can be optimized)
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                if (balances[i] < balances[j]) {
                    // Swap balances
                    uint256 tempBalance = balances[i];
                    balances[i] = balances[j];
                    balances[j] = tempBalance;

                    // Swap addresses
                    address tempHolder = holders[i];
                    holders[i] = holders[j];
                    holders[j] = tempHolder;
                }
            }
        }

        return (holders, balances);
    }

    // --- Convert Token to ETH ---
    function convertTokenToEth(uint256 tokenAmount) public view returns (uint256) {
        require(tokenAmount > 0, "Token amount must be greater than zero");
        return tokenAmount * tokenToEthRate / 10**decimals();
    }

    // --- Admin Functions ---
    function setDailyReward(uint256 rewardAmount) public onlyAdmin {
        baseDailyReward = rewardAmount;
    }

    function setGiftCodeReward(uint256 rewardAmount) public onlyAdmin {
        giftCodeReward = rewardAmount;
    }

    function setPreSaleRate(uint256 newRate) public onlyAdmin {
        preSaleRate = newRate;
    }

    function setTokenToEthRate(uint256 newRate) public onlyAdmin {
        tokenToEthRate = newRate;
    }
    // --- Get Balance ---
    function getBalance(address account) public view returns (uint256) {
        return balanceOf(account);
    }

}
