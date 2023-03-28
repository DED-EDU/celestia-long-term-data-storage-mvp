// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "lib/openzeppelin-contracts/contracts/utils/Counters.sol";

/// @title LearningSession
/// @author Amnot (@pynchmeister)
/// @notice This contract is to be used in the context of DED Arbitration, once a learning sessions is completed.
contract LearningSession {
    using Counters for Counters.Counter;

    enum LearningSessionArtifact {
        VIDEO,
        COMMENT
    }
    
    /// @notice Custom errors
    error ArtifactDoesNotExist();
    error ParentArtifactDoesNotExist();
    error InvalidVoteValue();
    
    /**  
    @notice A struct containing the learning session artifact info
    
    
    @param artifactType of artifact whether it be a video of the learning session or a comment on a video artifact thread
    @param id of the artifact
    @param parentId of the id uint256 hierarchly
    @param author address of the comment or video poster
    @param createdAtBlock time when the artifact was created
    @param childIds array of child artifacts
    @param CID content identifer - this is the cryptographic hash of the artifact content
    */
    struct Artifact {
        LearningSessionArtifact artifactType;
        uint256 id;
        uint256 parentId;
        address author;
        uint256 createdAtBlock;
        uint256[] childIds;
        string CID;
    }
    
    /**  
    @notice A struct containing the VoteCount (reputation) info
    
    
    @param votes mapping of voterIds to votes themselves
    @param total votes
    */
    struct VoteCount {
        mapping(bytes32 => int8) votes;
        int256 total;
    }

    Counters.Counter private artifactIdCounter;
    
    
    /**  
    @dev A mapping of votes to the VoteCount struct
    */
    mapping(uint256 => VoteCount) private artifactVotes;
    /**  
    @dev A mapping of addresses to the votes (otherwise known as reputation)
    */
    mapping(address => int256) private authorReputation;
    /**  
    @dev A mapping of ids to the Artifact structs
    */
    mapping(uint256 => Artifact) private artifacts;
    
    
    /// @notice This event is emitted when a new Artifact is created
    /// @param id The artifact id.
    /// @param parentId The parent id.
    /// @param author The author.
    event NewArtifact(
        uint256 indexed id,
        uint256 indexed parentId,
        address indexed author
    );
    
    /// @notice Add learning session artifact and emit NewArtifact event
    /// @param CID The content identfiier (CID) of the learning session video artifact
    function addSessionArtifact(string calldata CID) public {
        artifactIdCounter.increment();
        uint256 id = artifactIdCounter.current();
        address author = msg.sender;

        uint256[] memory childIds;
        artifacts[id] = Artifact(LearningSessionArtifact.VIDEO, id, 0, author, block.number, childIds, CID);
        emit NewArtifact(id, 0, author);

    }

    /// @notice Supply an aritfact id and return the Artifact struct it is assigned to 
    /// @param artifactId The unique id of an artifact
    /// @return Artifact (struct) in memory
    function getArtifact(uint256 artifactId) public view returns (Artifact memory) {
        if (artifacts[artifactId].id != artifactId) {
            revert ArtifactDoesNotExist();
        }        
        return artifacts[artifactId];
    }
    
    /// @notice Supply a parent id and CID to add a comment to a learning session artifact and emit a NewArtifact 
    /// event
    /// @param parentId The unique id of the parent artifact, CID The content identfiier (CID) of the learning session
    /// video artifact
    function addComment(uint256 parentId, string calldata CID) public {
        if (artifacts[parentId].id != parentId) {
            revert ParentArtifactDoesNotExist();
        }
        artifactIdCounter.increment();
        uint256 id = artifactIdCounter.current();
        address author = msg.sender;

        artifacts[parentId].childIds.push(id);

        uint256[] memory childIds;
        artifacts[id] = Artifact(LearningSessionArtifact.COMMENT, id, parentId, author, block.number, childIds, CID);
        emit NewArtifact(id, parentId, author);
    }
    
    
    /// @notice Supply an aritfact id and a vote value to assign successful or failed learning session 
    /// (goal is either accomplished or not)
    /// @dev This function is to be performed by (DED) 'Arbitrators'
    /// @param artifactId The unique id of an artifact, voteValue numeric value of the vote, can be -1, 0, or 1
    function vote(uint256 artifactId, int8 voteValue) public {
    if (artifacts[artifactId].id != artifactId) {
        revert ArtifactDoesNotExist();
    }
    if (voteValue < -1 || voteValue > 1) {
        revert InvalidVoteValue();
    }

    bytes32 voterId = _voterId(msg.sender);
    int8 oldVote = artifactVotes[artifactId].votes[voterId];

    // Obtain the storage slots for the mappings
    uint256 artifactVotes_slot;
    assembly {
        let memPtr := mload(0x40) // Get free memory pointer
        mstore(memPtr, 0x6172746966616374566f74657300000000000000000000000000000000000000) // Store "artifactVotes" at memPtr
        mstore(add(memPtr, 0x20), artifactId) // Store artifactId after "artifactVotes"
        artifactVotes_slot := keccak256(memPtr, 0x40) // Calculate keccak256 hash using assembly
    }
    uint256 authorReputation_slot;
    assembly {
        let memPtr := mload(0x40) // Get free memory pointer
        mstore(memPtr, 0x617574686f7252657075746174696f6e00000000000000000000000000000000) // Store "authorReputation" at memPtr
        authorReputation_slot := keccak256(memPtr, 0x20) // Calculate keccak256 hash using assembly
    }

    uint256 artifacts_slot;
    assembly {
        let memPtr := mload(0x40) // Get free memory pointer
        mstore(memPtr, 0x6172746966616374730000000000000000000000000000000000000000000000) // Store "artifacts" at memPtr
        mstore(add(memPtr, 0x20), artifactId) // Store artifactId after "artifacts"
        artifacts_slot := keccak256(memPtr, 0x40) // Calculate keccak256 hash using assembly
    }

    assembly {
        // Check if oldVote is different from voteValue
        if iszero(eq(oldVote, voteValue)) {
            // Update the vote value in the votes mapping
            sstore(add(artifactVotes_slot, voterId), voteValue)

            // Calculate the updated total vote count
            let total := add(sload(artifactVotes_slot), sub(voteValue, oldVote))
            // Update the total vote count in the total mapping
            sstore(artifactVotes_slot, total)

            // Load the author address from the artifacts mapping
            let author := sload(artifacts_slot)

            // Check if author is not the same as the sender
            if iszero(eq(author, caller())) {
                // Calculate the updated author reputation
                let reputation := add(sload(authorReputation_slot), sub(voteValue, oldVote))
                // Update the author reputation in the authorReputation mapping
                sstore(authorReputation_slot, reputation)
            }
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
    /// @param author The address of an author
    /// @return int256
    function getAuthorReputation(address author) public view returns (int256) {
        return authorReputation[author];
    }

    /// @notice Supply a voter address and return the associated voter id
    /// @param voter The address of a voter
    /// @return bytes32
    function _voterId(address voter) internal pure returns (bytes32) {
        bytes32 result;
        assembly { result := keccak256(add(voter, 0x20), 0x20) }
  }
}
