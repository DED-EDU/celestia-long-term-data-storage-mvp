# celestia-long-term-data-storage-mvp
Long-Term Data Storage with Celestia Rollups using Ethermint

## prerequisites

* Have a [Celestia light client](https://docs.celestia.org/nodes/light-node/) up and running
* Complete the [Ethermint tutorials](https://docs.celestia.org/category/ethermint) from Celestia's documentation

### instructions

Create a Solidity smart contract that our IPFS hash/content identifier (CID) can be stored in. Ours looks similar to this:

```
// SPDX-License-Identifier: Unlicense
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
// SPDX-License-Identifier: Unlicense
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
  ipfs: "0xdc64a140aa3e981100a9beca4e685f962f0cf6c9",
};

export default addresses;
```

We will now navigate to the ```react-app``` directory so that we can make our edits in the main ```App.js``` file.
