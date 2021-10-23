//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OctopusFun is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Counts number of alive NFTs
    Counters.Counter public aliveNFTCount;  

    // Counts number of alive NFTs in the last round to calculate proper payout since aliveNFTCount doesn't account for players who forgot to play rounds
    Counters.Counter public lastRoundAliveNFTCount;  

    mapping(address => uint256) public aliveNFTs;  // Maps address to current round that player is in
    mapping(address => uint256) public deadNFTs;  // Maps address to current round that player is in
    mapping(address => uint256) public addressToTokenId;  // Maps address to token Id

    uint256 public constant MAX_OCTOPUS_FUN_TOKENS = 456;  // Only 456 total NFTs can be minted!
    uint256 public constant COST_TO_MINT = 100000000000000000; // 0.1 Ether

    constructor() ERC721("OctopusFun", "OCF") {}

    function mintNFT(address recipient, string memory tokenURI)
        external
        payable
        returns (uint256)
    {
        // require(COST_TO_MINT <= msg.value, "Ether value sent is not correct"); 
        require(_tokenIds.current()<MAX_OCTOPUS_FUN_TOKENS, "We have reached the max number of players, try again next time");
        require(aliveNFTs[recipient] == 0  && deadNFTs[recipient] == 0);

        _tokenIds.increment();
        aliveNFTCount.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        aliveNFTs[recipient] = 1; // set each new minted NFT as alive and starting on round 1
        addressToTokenId[recipient] = newItemId;

        return newItemId;
    }

    //Override all transfer functions to keep track of alive NFT player addresses
    // Problem: If a an address transfers the token, aliveNFTs list will not be updated with the latest address of active players
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
    {
        require(aliveNFTs[to] == 0  && deadNFTs[to] == 0);
        super.safeTransferFrom(from, to, tokenId);
        if(aliveNFTs[from] > 0 ) { // Make sure alive. Doesn't matter if dead (also save some gas)
            aliveNFTs[to] = aliveNFTs[from]; // Set the round of the new owner to the round of the previous owner
            aliveNFTs[from] = 0;  // Zero out the round of the previous owner
            addressToTokenId[to] = addressToTokenId[from];  // transfer tokenId from addresses
            addressToTokenId[from] = 0;  // Zero out token Id 
        } 
    }

    //Override all transfer functions to keep track of alive NFT player addresses
    // Problem: If a an address transfers the token, aliveNFTs list will not be updated with the latest address of active players
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
    {
        require(aliveNFTs[to] == 0  && deadNFTs[to] == 0);
        super.transferFrom(from, to, tokenId);
        if(aliveNFTs[from] > 0 ) { // Make sure alive. Doesn't matter if dead (also save some gas)
            aliveNFTs[to] = aliveNFTs[from]; // Set the round of the new owner to the round of the previous owner
            aliveNFTs[from] = 0;  // Zero out the round of the previous owner
            addressToTokenId[to] = addressToTokenId[from];  // transfer tokenId from addresses
            addressToTokenId[from] = 0;  // Zero out token Id 
        } 
    }

    //Override all transfer functions to keep track of alive NFT player addresses
    // Problem: If a an address transfers the token, aliveNFTs list will not be updated with the latest address of active players
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
    {
        require(aliveNFTs[to] == 0  && deadNFTs[to] == 0);
        super.safeTransferFrom(from, to, tokenId, data);
        if(aliveNFTs[from] > 0 ) { // Make sure alive. Doesn't matter if dead (also save some gas)
            aliveNFTs[to] = aliveNFTs[from]; // Set the round of the new owner to the round of the previous owner
            aliveNFTs[from] = 0;  // Zero out the round of the previous owner
            addressToTokenId[to] = addressToTokenId[from];  // transfer tokenId from addresses
            addressToTokenId[from] = 0;  // Zero out token Id 
        } 
    }

    // Basic gameplay
    // - Keep a list of all alive & dead tokens. Populate list of alive in minting.
    // - Each round has a specific start and end time. If you fail to participate in any week, your NFT is automatically eliminated
    // - At the end of round 6 or if there's only one NFT alive, the token holder(s) can check if they're a winner and payout with the checkIfWinnerAndPayout() function

    // Returns a random number between 0-999, used to randomly determine if NFT passes or does not pass round
    function rand()
        public
        view
        returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / 1000) * 1000));
    }

     // Returns a random number between 0-999, used to randomly determine if NFT passes or does not pass round
    function getTokenURIFromAddress(address player)
        public
        view
        returns(string memory)
    {
        uint256 tokenIdOfAddress = addressToTokenId[player];
        require(tokenIdOfAddress != 0, "Your address does not have a token");
        return tokenURI(tokenIdOfAddress);
    }

     // Returns a random number between 0-999, used to randomly determine if NFT passes or does not pass round
    function checkIfPlayerIsAlive(address player)
        public
        view
        returns(bool)
    {
        return aliveNFTs[player]>0;
    }

    // Starts on Wednesday, October 20, 2021 10:00:00 AM GMT
    function playRound1(address player)
        external
        nonReentrant
        returns(string memory)
    {
        require(player == msg.sender, "It seems like you are not the owner of this token...");
        // require(block.timestamp>1634724000 && block.timestamp<1634810400, "Sorry, it is not time for round 1.");
        uint256 roundThatPlayerIsIn = aliveNFTs[player];
        require(roundThatPlayerIsIn != 0 && roundThatPlayerIsIn == 1, "Must be a player with an NFT that's alive and in round 1!");

        uint256 chanceOfSurvival = rand(); 
        if(chanceOfSurvival < 499){ // ~50% chance of surviving round 1
            eliminateNFT(player, roundThatPlayerIsIn);
            return "Sorry, you were eliminated from round 1.";
        }

        aliveNFTs[player] = aliveNFTs[player] + 1; // increment the round that the player is on
        return "Congrats, you survived round 1.";
    }

    // Starts on Thursday, October 21, 2021 10:00:00 AM GMT
    function playRound2(address player)
        external
        nonReentrant
        returns(string memory)
    {
        require(player == msg.sender, "It seems like you are not the owner of this token...");
        // require(block.timestamp>1634810400 && block.timestamp<1634896800, "Sorry, it is not time for round 2.");
        uint256 roundThatPlayerIsIn = aliveNFTs[player];
        require(roundThatPlayerIsIn != 0 && roundThatPlayerIsIn == 2, "Must be a player with an NFT that's alive and in round 2!");

        uint256 chanceOfSurvival = rand(); 
        if(chanceOfSurvival < 499){ // ~50% chance of surviving round 2
            eliminateNFT(player, roundThatPlayerIsIn);
            return "Sorry, you were eliminated from round 2.";
        }

        aliveNFTs[player] = aliveNFTs[player] + 1; // increment the round that the player is on
        return "Congrats, you survived round 2.";
    }

    // Starts on Friday, October 22, 2021 10:00:00 AM GMT
    function playRound3(address player)
        external
        nonReentrant
        returns(string memory)
    {
        require(player == msg.sender, "It seems like you are not the owner of this token...");
        // require(block.timestamp>1634896800 && block.timestamp<1634904000000, "Sorry, it is not time for round 3.");
        uint256 roundThatPlayerIsIn = aliveNFTs[player];
        require(roundThatPlayerIsIn != 0 && roundThatPlayerIsIn == 3, "Must be a player with an NFT that's alive and in round 3!");

        uint256 chanceOfSurvival = rand(); 
        if(chanceOfSurvival < 499){ // ~50% chance of surviving round 3
            eliminateNFT(player, roundThatPlayerIsIn);
            return "Sorry, you were eliminated from round 3.";
        }

        aliveNFTs[player] = aliveNFTs[player] + 1; // increment the round that the player is on
        lastRoundAliveNFTCount.increment();
        return "Congrats, you survived round 3.";
    }

    // Starts on Friday, October 22, 2021 10:00:00 AM GMT
    function playRound4(address player)
        external
        nonReentrant
        returns(string memory)
    {
        require(player == msg.sender, "It seems like you are not the owner of this token...");
        // require(block.timestamp>1634896800 && block.timestamp<1634904000000, "Sorry, it is not time for round 3.");
        uint256 roundThatPlayerIsIn = aliveNFTs[player];
        require(roundThatPlayerIsIn != 0 && roundThatPlayerIsIn == 4, "Must be a player with an NFT that's alive and in round 4!");

        uint256 chanceOfSurvival = rand(); 
        if(chanceOfSurvival < 499){ // ~50% chance of surviving round 4
            eliminateNFT(player, roundThatPlayerIsIn);
            return "Sorry, you were eliminated from round 4.";
        }

        aliveNFTs[player] = aliveNFTs[player] + 1; // increment the round that the player is on
        lastRoundAliveNFTCount.increment();
        return "Congrats, you survived round 4.";
    }

    function playRound5(address player)
        external
        nonReentrant
        returns(string memory)
    {
        require(player == msg.sender, "It seems like you are not the owner of this token...");
        // require(block.timestamp>1634896800 && block.timestamp<1634904000000, "Sorry, it is not time for round 3.");
        uint256 roundThatPlayerIsIn = aliveNFTs[player];
        require(roundThatPlayerIsIn != 0 && roundThatPlayerIsIn == 5, "Must be a player with an NFT that's alive and in round 5!");

        uint256 chanceOfSurvival = rand(); 
        if(chanceOfSurvival < 499){ // ~50% chance of surviving round 5
            eliminateNFT(player, roundThatPlayerIsIn);
            return "Sorry, you were eliminated from round 5.";
        }

        aliveNFTs[player] = aliveNFTs[player] + 1; // increment the round that the player is on
        lastRoundAliveNFTCount.increment();
        return "Congrats, you survived round 5.";
    }

    function playRound6(address player)
        external
        nonReentrant
        returns(string memory)
    {
        require(player == msg.sender, "It seems like you are not the owner of this token...");
        // require(block.timestamp>1634896800 && block.timestamp<1634904000000, "Sorry, it is not time for round 6.");
        uint256 roundThatPlayerIsIn = aliveNFTs[player];
        require(roundThatPlayerIsIn != 0 && roundThatPlayerIsIn == 6, "Must be a player with an NFT that's alive and in round 6!");

        uint256 chanceOfSurvival = rand(); 
        if(chanceOfSurvival < 499){ // ~50% chance of surviving round 6
            eliminateNFT(player, roundThatPlayerIsIn);
            return "Sorry, you were eliminated from round 6.";
        }

        aliveNFTs[player] = aliveNFTs[player] + 1; // increment the round that the player is on
        lastRoundAliveNFTCount.increment();
        return "Congrats, you survived round 6.";
    }

    function eliminateNFT(address player, uint256 roundThatPlayerIsIn) 
        private
    {
        aliveNFTs[player] = 0;  // Zero out the round that the player is on, effectively removing them from the aliveNFTs list
        deadNFTs[player] = roundThatPlayerIsIn;  // Move player to deadNFTs list
        aliveNFTCount.decrement();
    }

    // If there's one player left, payout to solo winner!
    // Else, check that round 6 (Ends on Friday, October 22, 2021 3:00:00 PM GMT) is over & split the winnings
    function checkIfWinnerAndPayout(address player, uint256 tokenId) 
        public
        nonReentrant
        payable
        returns(string memory)
    {
        address ownerOfTokenId = ownerOf(tokenId);
        require(player == ownerOfTokenId && player == msg.sender && ownerOfTokenId == msg.sender, "It seems like you are not the owner of this token...");

        if(aliveNFTCount.current() == 1) {
            require(aliveNFTs[player] != 0, "You are not the winner this time");
            
            address winnerAddress = player;
            uint256 balance = address(this).balance;
            payable(winnerAddress).transfer(balance);
        } else {
            // require(block.timestamp>1634904000000, "Be patient, the game is not finished");
            uint256 roundThatPlayerIsIn = aliveNFTs[player];
            require(roundThatPlayerIsIn != 0 && roundThatPlayerIsIn == 4, "Must be a player with an NFT that's alive and passed all 3 rounds!");

            uint256 balance = address(this).balance;
            uint256 numberOfWinners = lastRoundAliveNFTCount.current();
            uint256 payoutToEachWinner = balance/numberOfWinners;
            payable(player).transfer(payoutToEachWinner);
        }

        return "You've won! Here's your winnings";
    }

}
