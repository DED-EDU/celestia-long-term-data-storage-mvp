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

    struct Artifact {

        learningSessionArtifact type;

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

    Counters.Counter private artifactIdCounter;

    mapping(uint256 => VoteCount) private artifactVotes;

    mapping(address => int256) private authorReputation;

    mapping(uint256 => Item) private artifacts;

    event NewArtifact(
        uint256 indexed id,
        uint256 indexed parentId,
        address indexed author
    );

    function addSessionArtifact(string memory contentCID) public {
        artifactIdCounter.increment();
        uint256 id = artifactIdCounter.current();
        address author = msg.sender;

        uint256[] memory childIds;
        artifacts[id] = Artifact(learningSessionArtifact.VIDEO, id, 0, author, block.number, childIds, contentCID);
        emit NewArtifact(id, 0, author);

    }

    function getItem(uint256 artifactId) public view returns (Artifact memory) {
        require(artifacts[artifactId].id == artifactId, "Artifact does not exist");
        return artifacts[artifactId];
    }

    function addComment(uint256 parentId, string memory contentCID) public {
        require(artifacts[parentId].id == parentId, "Parent artifact does not exist");

        artifactIdCounter.increment();
        uint256 id = artifactIdCounter.current();
        address author = msg.sender;

        artifacts[parentId].childIds.push(id);

        uint256[] memory childIds;
        artifacts[id] = Artifact(learningSessionArtifact.COMMENT, id, parentId, author, block.number, childIds, contentCID);
        emit NewArtifact(id, parentId, author);
    }

    function vote(uint256 artifactId, int8 voteValue) public {
        require(artifacts[artifactId].id == artifactId, "Artifact does not exist");
        require(voteValue >= -1 && voteValue <= 1, "Invalid vote value. Must be -1, 0, or 1");

        bytes32 voterId = _voterId(msg.sender);
        int8 oldVote = artifactVotes[artifactId].votes[voterId];

        if (oldVote != voteValue) {
            artifactVotes[artifactId].votes[voterId] = voteValue;
            artifactVotes[artifactId].total = artifactVotes[artifactId].total - oldVote + voteValue;

            address author = artifacts[artifactId].author;
            if (author != msg.sender) {
                authorReputation[author] = authorReputation[author] - oldVote + voteValue;
            }
        }

    }

    function getArtifactScore(uint256 itemId) public view returns (int256) {
        return artifactVotes[artifactId].total;
    }

    function getAuthorReputation(address author) public view returns (int256) {
        return authorReputation[author];
    }

     function _voterId(address voter) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(voter));
  }

}
