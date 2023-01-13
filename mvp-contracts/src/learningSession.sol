//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/utils/Counters.sol";

/// @title learningSession
/// @author Harris Levine (@pynchmeister)
/// @notice This contract is to be used in the context of DED Arbitration, once a learning sessions is completed.
contract learningSession {
    using Counters for Counters.Counter;

    enum learningSessionArtifact {
        VIDEO,
        COMMENT
    }
    
    /**  
    A struct containing the learning session artifact info
    @param type of artifact whether it be a video of the learning session or a comment on a video artifact thread
    @param id of the artifact
    @param parentId of the id uint256 hierarchly
    @param author address of the comment or video poster
    @param createdAtBlock time when the artifact was created
    @param childIds array of child artifacts
    @param CID content identifer - this is the cryptographic hash of the artifact content
    */
    struct Artifact {

        learningSessionArtifact type;

        uint256 id;

        uint256 parentId;

        address author;

        uint256 createdAtBlock;

        uint256[] childIds;

        string CID;
    }

    struct VoteCount {

        mapping(bytes32 => int8) votes;

        int256 total;

    }

    Counters.Counter private artifactIdCounter;

    mapping(uint256 => VoteCount) private artifactVotes;

    mapping(address => int256) private authorReputation;

    mapping(uint256 => Artifact) private artifacts;

    event NewArtifact(
        uint256 indexed id,
        uint256 indexed parentId,
        address indexed author
    );
    
    /// @notice Add learning session artifact and emit NewArtifact event
    /// @param CID The content identfiier (CID) of the learning session video artifact
    function addSessionArtifact(string memory CID) public {
        artifactIdCounter.increment();
        uint256 id = artifactIdCounter.current();
        address author = msg.sender;

        uint256[] memory childIds;
        artifacts[id] = Artifact(learningSessionArtifact.VIDEO, id, 0, author, block.number, childIds, CID);
        emit NewArtifact(id, 0, author);

    }

    /// @notice Supply an aritfact id and return the Artifact struct it is assigned to 
    /// @param artifactId The unique id of an artifact
    /// @return Artifact (struct) in memory
    function getItem(uint256 artifactId) public view returns (Artifact memory) {
        require(artifacts[artifactId].id == artifactId, "Artifact does not exist");
        return artifacts[artifactId];
    }
    
    /// @notice Supply a parent id and CID to add a comment to a learning session artifact and emit a NewArtifact 
    /// event
    /// @param parentId The unique id of the parent artifact, CID The content identfiier (CID) of the learning session
    /// video artifact
    function addComment(uint256 parentId, string memory CID) public {
        require(artifacts[parentId].id == parentId, "Parent artifact does not exist");

        artifactIdCounter.increment();
        uint256 id = artifactIdCounter.current();
        address author = msg.sender;

        artifacts[parentId].childIds.push(id);

        uint256[] memory childIds;
        artifacts[id] = Artifact(learningSessionArtifact.COMMENT, id, parentId, author, block.number, childIds, CID);
        emit NewArtifact(id, parentId, author);
    }
    
    
    /// @notice Supply an aritfact id and a vote value to assign successful or failed learning session 
    /// (goal is either accomplished or not)
    /// @dev This function is to be performed by (DED) 'Arbitrators'
    /// @param artifactId The unique id of an artifact, voteValue numeric value of the vote, can be -1, 0, or 1
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
    
    /// @notice Supply an artifactId  and return the accompanying Artifact repuation score
    /// @param artifactId The unique id of an artifact
    /// @return int256
    function getArtifactScore(uint256 artifactId) public view returns (int256) {
        return artifactVotes[artifactId].total;
    }
    
    
    /// @notice Supply an author address and return the reputation score of the Artifact
    /// @param artifactId The address of an author
    /// @return int256
    function getAuthorReputation(address author) public view returns (int256) {
        return authorReputation[author];
    }

    /// @notice Supply a voter address and return the associated voter id
    /// @param voter The address of a voter
    /// @return bytes32
    function _voterId(address voter) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(voter));
  }

}
