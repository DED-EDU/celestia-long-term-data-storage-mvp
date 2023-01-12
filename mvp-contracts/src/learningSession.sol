//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/utils/Counters.sol";

contract learningSession {
    using Counters for Counters.Counter;

    enum learningSessionArtifact {
        VIDEO,
        COMMENT
    }

    struct Item {

        learningSessionArtifact kind;

        uint256 id;

        uint256 parentId;

        address author;

        uint256 createdAtBlock;

        uint256[] childIds;

        string contentCID;
    }

    struct VoteCount {

        mapping(bytes32 => int8) votes;

        int256 total;

    }

    Counters.Counter private itemIdCounter;

    mapping(uint256 => VoteCount) private itemVotes;

    mapping(address => int256) private authorReputation;

    mapping(uint256 => Item) private items;

    event NewItem(
        uint256 indexed id,
        uint256 indexed parentId,
        address indexed author
    );

    function addSessionArtifact(string memory contentCID) public {
        itemIdCounter.increment();
        uint256 id = itemIdCounter.current();
        address author = msg.sender;

        uint256[] memory childIds;
        items[id] = Item(learningSessionArtifact.VIDEO, id, 0, author, block.number, childIds, contentCID);
        emit NewItem(id, 0, author);

    }

    function getItem(uint256 itemId) public view returns (Item memory) {
        require(items[itemId].id == itemId, "Item does not exist");
        return items[itemId];
    }

    function addComment(uint256 parentId, string memory contentCID) public {
        require(items[parentId].id == parentId, "Parent item does not exist");

        itemIdCounter.increment();
        uint256 id = itemIdCounter.current();
        address author = msg.sender;

        items[parentId].childIds.push(id);

        uint256[] memory childIds;
        items[id] = Item(learningSessionArtifact.COMMENT, id, parentId, author, block.number, childIds, contentCID);
        emit NewItem(id, parentId, author);
    }

    function vote(uint256 itemId, int8 voteValue) public {
        require(items[itemId].id == itemId, "Item does not exist");
        require(voteValue >= -1 && voteValue <= 1, "Invalid vote value. Must be -1, 0, or 1");

        bytes32 voterId = _voterId(msg.sender);
        int8 oldVote = itemVotes[itemId].votes[voterId];

        if (oldVote != voteValue) {
            itemVotes[itemId].votes[voterId] = voteValue;
            itemVotes[itemId].total = itemVotes[itemId].total - oldVote + voteValue;

            address author = items[itemId].author;
            if (author != msg.sender) {
                authorReputation[author] = authorReputation[author] - oldVote + voteValue;
            }
        }

    }

    function getItemScore(uint256 itemId) public view returns (int256) {
        return itemVotes[itemId].total;
    }

    function getAuthorReputation(address author) public view returns (int256) {
        return authorReputation[author];
    }

     function _voterId(address voter) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(voter));
  }

}
