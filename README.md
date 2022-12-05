# celestia-long-term-data-storage-mvp
Long-Term Data Storage with Celestia Rollups using Ethermint

## prerequisites

* Have a [Celestia light client](https://docs.celestia.org/nodes/light-node/) up and running
* Complete the [Ethermint tutorials](https://docs.celestia.org/category/ethermint) from Celestia's documentation

### instructions

Create a Solidity smart contract that our IPFS hash/content identifier (CID) can be stored in. Ours looks similar to this:

```
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

```
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

```
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

```
const addresses = {
  storage: "0xdc64a140aa3e981100a9beca4e685f962f0cf6c9",
};

export default addresses;
```

We will now navigate to the ```react-app``` directory so that we can make our edits in the main ```App.js``` file.

We can import IPFS and initialize the node like so:

```
import IPFS from "ipfs";

async function initIpfs() {
  node = await IPFS.create();
  const version = await node.version();
  console.log("IPFS Node Version:", version.version);
}
```

We can add a function to read the current file from our Solidity smart contract. Note: we are using ethers.js for certain helper functions such as ```getSigner()```, ```getAddress()```, etc.

Here is an example of how that may look:

```
async function readCurrentUserFile() {
  const result = await storageContract.userFiles(
    defaultProvider.getSigner().getAddress()
  );

  return result;
}
```

The next functions created willl be ```uploadFile()```, which uploads a file using our IPFS node, and ```setFile()``` that stores our IPFS hash/CID inside our function once an upload is successful. As follows is an example of what the aforementioned functions look like:

```
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
