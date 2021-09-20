// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract GOT20VRF is VRFConsumerBase, Ownable {
    bytes32 private s_keyHash;
    uint256 private s_fee;
    uint256 private constant ROLL_IN_PROGRESS = 42;

    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);

    mapping(bytes32 => address) private s_rollers;
    mapping(address => uint256) private s_results;

    constructor(
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        uint256 fee
    ) public VRFConsumerBase(vrfCoordinator, link) {
        console.log("GOT20VRF: Using the following Corrdinator: %s", vrfCoordinator);
        s_keyHash = keyHash;
        s_fee = fee;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 d20Value = (randomness % 20) + 1;
        s_results[s_rollers[requestId]] = d20Value;
        emit DiceLanded(requestId, d20Value);
    }

    function rollDice(address roller)
        public
        onlyOwner
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= s_fee,
            "Not enough LINK to pay fee"
        );
        require(s_results[roller] == 0, "Already rolled");

        // async, request randomness and applie it later
        requestId = requestRandomness(s_keyHash, s_fee);

        s_rollers[requestId] = roller;
        // mark as (is rolling)
        s_results[roller] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, roller);
    }

    function house(address player) public view returns (string memory) {
        require(s_results[player] != 0, "Dice not rolled");
        require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");
        return getHouseName(s_results[player]);
    }

    function getHouseName(uint256 id) private pure returns (string memory) {
        string[20] memory houseNames = [
            "Targaryen",
            "Lannister",
            "Stark",
            "Tyrell",
            "Baratheon",
            "Martell",
            "Tully",
            "Bolton",
            "Greyjoy",
            "Arryn",
            "Frey",
            "Mormont",
            "Tarley",
            "Dayne",
            "Umber",
            "Valeryon",
            "Manderly",
            "Clegane",
            "Glover",
            "Karstark"
        ];
        return houseNames[id.sub(1)];
    }
}
