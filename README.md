# celestia-long-term-data-storage-mvp
Long-Term Data Storage with Celestia Rollups using Ethermint

## prerequisites

* Have a [Celestia light client](https://docs.celestia.org/nodes/light-node/) up and running
* Complete the [Ethermint tutorials](https://docs.celestia.org/category/ethermint) from Celestia's documentation

### instructions

Create a Solidity smart contract that our IPFS hash/content identifier (CID) can be stored in. Ours looks similar to this:

```solidity
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

contract Storage {
    mapping (address => string) public userFiles;

    function setFile(string memory file) external {
        userFiles[msg.sender] = file;
    }
}
```

Deploy this contract on Ethermint with a script similar to the following:

```solidity
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Storage} from "src/Storage.sol";

contract StorageScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new Storage();
        vm.stopBroadcast();
    }
}
```

https://user-images.githubusercontent.com/33232379/205630372-4f51147f-e573-4629-a771-a9213d5814d1.mov

Once met with a successful deployment, we can begin creating the frontend. Be sure to keep track of your contract(s) deployment address as we will need that in a bit.

We'll be using [create-eth-app](https://github.com/paulrberg/create-eth-app) to scaffold a development environment. Once we are within the proper directory, it is quite important to add the latest stable version of IPFS.

We will also need to navigate to the directory ```packages/contracts/src/abis``` and add the accompanying json file to your Solidity smart contract.

Next, navigate to ```packages/contracts/src/abis.js``` and add your newly created json as an import, and then instantiate it, like so:

```javascript
import erc20Abi from "./abis/erc20.json";
import ownableAbi from "./abis/ownable.json";
import ipfsStorage from "./abis/Storage.json";

const abis = {
  erc20: erc20Abi,
  ownable: ownableAbi,
  storage: Storage,
};

export default abis;
```

Finally we need to navigate to ```addresses.js``` in the same directory and alter it like so:

```javascript
const addresses = {
  storage: "0xdc64a140aa3e981100a9beca4e685f962f0cf6c9",
};

export default addresses;
```

We will now navigate to the ```react-app``` directory so that we can make our edits in the main ```App.js``` file.

We can import IPFS and initialize the node like so:

```javascript
import IPFS from "ipfs";

async function initIpfs() {
  node = await IPFS.create();
  const version = await node.version();
  console.log("IPFS Node Version:", version.version);
}
```

We can add a function to read the current file from our Solidity smart contract. Note: we are using ethers.js for certain helper functions such as ```getSigner()```, ```getAddress()```, etc.

Here is an example of how that may look:

```javascript
async function readCurrentUserFile() {
  const result = await storageContract.userFiles(
    defaultProvider.getSigner().getAddress()
  );

  return result;
}
```

The next functions created will be ```uploadFile()```, which uploads a file using our IPFS node, and ```setFile()``` that stores our IPFS hash/CID inside our function once an upload is successful. As follows is an example of what the aforementioned functions look like:

```javascript
async function setFile(hash) {
    const ipfsWithSigner = storageContract.connect(defaultProvider.getSigner());
    await ipfsWithSigner.setFile(hash);
    setIpfsHash(hash);
}

async function uploadFile(file) {
    const files = [{ path: file.name + file.path, content: file }];

    for await (const result of node.add(files)) {
        await setFile(result.cid.string);
    }
}
```

Now we can move on to UI development. Since this is a bit out of scope I won't go delve too deep, but the code can be viewed in full within this repository.

The final step is setting up Metamask with a new network for Ethermint on RPC_URL 9545. This is to ensure the contract address is recognized properly. In order to have funds to run the contract calls we can import a new account using our anvil private key. As follows is a visual of how the network addition process should work:

<img width="346" alt="Screen Shot 2022-12-05 at 6 12 36 AM" src="https://user-images.githubusercontent.com/33232379/205623697-9e68ca0f-3aaa-4072-b38a-93447a6e0880.png">

I have also included a short clip of the user story (upload of a file to IPFS and CID resolution to display content) as follows:

https://user-images.githubusercontent.com/33232379/205629365-5ae693a1-9ba7-4416-b867-d12b765ebe1c.mov


#### Extending Functionality to a Decentralized Education Development Learning Session

A LearningSession smart contract is deployed with Rollkit + Ethermint, in the same fashion as is aforementioned with the Storage contract. This enables DED 'Students' to upload an "Artifact" of their learning session: most often a video. Once uploaded 'Arbitrators' may comment and vote on the validity of whether a given learning session's goal(s) was accomplished.

##### Artifacts

```solidity 
    /**  
    /*
    @notice A struct containing the learning session artifact info
    
    
    @param type of artifact whether it be a video of the learning session or a comment on a video artifact thread
    @param id of the artifact
    @param parentId of the id uint256 hierarchly
    @param author address of the comment or video poster
    @param createdAtBlock time when the artifact was created
    @param childIds array of child artifacts
    @param CID content identifer - this is the cryptographic hash of the artifact content
    */
    struct Artifact {

        LearningSessionArtifact type;

        uint256 id;

        uint256 parentId;

        address author;

        uint256 createdAtBlock;

        uint256[] childIds;

        string CID;
    }

```

The ```Artifact``` has a ```type``` field that can have two options as can be seen below:

```solidity

 enum LearningSessionArtifact {
        VIDEO,
        COMMENT
    }
    
```

When a user adds a comment on a post, that comment is connected to the original post (or comment) through a parentId field. The parent post or comment will then have a list of its child comments in a childIds field. When a new comment is added, the parent's childIds list is updated to include the new comment.

The text or information in a post or comment is saved as a JSON file in both IPFS and Filecoin by using Web3.Storage. The content identifier of that file, called a CID, is then stored in a field named CID.

To view a comment or post, you can use a contract function called getArtifact and input the ucontent identifier of the item. After this, you will need to obtain the content from IPFS, then interpret the JSON file in order to fully display the item.

##### Reputation / Voting

Individuals can express their opinion on a learning session artifact or comment by using the vote(artifactId, voteValue) function, where voteValue can be -1 for a downvote, +1 for an upvote, or 0 to withdraw a previous vote.

It is only possible for one vote per account per artifact or comment, any subsequent votes will replace the previous vote from that account.

The total number of votes for a artifact or comment can be obtained by using the getArtifactScore(artifactId) function, which calculates the sum of all upvotes and downvotes.

To find out the "reputation" or total number of votes received by an author for their artifacts and comments, use the getAuthorReputation(author) function by providing the author's address.

These functions can be viewed below:

```solidity
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
```

###### Navigating through this repository

The foundry setup for this project can be found [here](https://github.com/DED-EDU/celestia-long-term-data-storage-mvp/tree/main/mvp-contracts) while the frontend can be found [here](https://github.com/DED-EDU/celestia-long-term-data-storage-mvp/tree/main/mvp-dapp)
