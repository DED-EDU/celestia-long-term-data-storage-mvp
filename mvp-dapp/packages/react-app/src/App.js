import React, { useCallback, useEffect, useState } from "react";
import { useDropzone } from "react-dropzone";
import { ethers } from "ethers";
import IPFS from "ipfs";

import logo from "./ethereumLogo.png";
import { addresses, abis } from "@project/contracts";
import { Web3Storage, getFilesFromPath } from "web3.storage";

import { mainnet } from '@filecoin-shipyard/lotus-client-schema?module';
import { BrowserProvider } from '@filecoin-shipyard/lotus-client-provider-browser?module';
import { LotusRPC } from '@filecoin-shipyard/lotus-client-rpc?module';

import "./App.css";

const ZERO_ADDRESS =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

const endpointUrl = 'wss://lotus.testground.ipfs.team/api/0/node/rpc/v0'

const provider = new BrowserProvider(endpointUrl)

const client = new LotusRPC(provider, { schema: mainnet.fullNode })

async function run () {
  try {
    const version = await client.version()
    console.log('Version', version)
  } catch (e) {
    console.error('client.version error', e)
  }
  await client.destroy()
}
run()


// Lotus client storage commands
  // lotus client import yourfile.txt

  // creates a DAG with the file and returns the CID

  // make note of the CID

  // lotus client deal

  // lotus client list-deals --show-failed

// Lotus client retrieval commands 

  // FULLNODE_API_INFO=wss://api.chain.love lotus daemon --lite

  // lotus wallet list

  // lotus client retrieve --provider <MINER ID> <PAYLOAD CID> ~/output-file
  




let node;

const defaultProvider = new ethers.providers.Web3Provider(window.ethereum);
const ipfsContract = new ethers.Contract(
  addresses.ipfs,
  abis.ipfs,
  defaultProvider
);

const learningSessionContract = new ethers.Contract(
  addresses.learningSession,
  abis.learningSession,
  defaultProvider
);

async function useIpfsLotus() {
// Start the IPFS daemon on the same machine as your Lotus node:
// ipfs daemon

// Open ~/.lotus/config.toml and add the following lines:
// [Client]
// UseIpfs = true

// Restart your IPFS and Lotus daemon.

// ipfs add -r your_example.txt
// keep note of the CID

// lotus client deal CID t01000 <price> <duration>
}
async function initIpfs() {
  node = await IPFS.create();
  const version = await node.version();
  console.log("IPFS Node Version:", version.version);
}

async function readCurrentUserFile() {
  const result = await ipfsContract.userFiles(
    defaultProvider.getSigner().getAddress()
  );
  console.log({ result });

  return result;
}

async function Web3StorageUpload(file) {

const storage = new Web3Storage({ token: process.env.WEB3_TOKEN })
const files = await getFilesFromPath(process.env.PATH_TO_ADD)
const cid = await storage.put(files)
console.log(`IPFS CID: ${cid}`)
console.log(`Gateway URL: https://dweb.link/ipfs/${cid}`)

}

function App() {
  const [ipfsHash, setIpfsHash] = useState("");
  useEffect(() => {
    initIpfs();
    window.ethereum.enable();
  }, []);

  useEffect(() => {
    async function readFile() {
      const file = await readCurrentUserFile();

      if (file !== ZERO_ADDRESS) setIpfsHash(file);
    }
    readFile();
  }, []);

  async function setFile(hash) {
    const ipfsWithSigner = ipfsContract.connect(defaultProvider.getSigner());
    const tx = await ipfsWithSigner.setFile(hash);
    console.log({ tx });

    setIpfsHash(hash);
  }

  const uploadFile = useCallback(async (file) => {
    const files = [
      {
        path: file.name + file.path,
        content: file,
      },
    ];

    for await (const result of node.add(files)) {
      await setFile(result.cid.string);
    }
  }, []);

  const onDrop = useCallback(
    (acceptedFiles) => {
      uploadFile(acceptedFiles[0]);
    },
    [uploadFile]
  );
  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    multiple: false,
    onDrop,
  });

  return (
    <div className="App">
      <header className="App-header">
        <div {...getRootProps()} style={{ cursor: "pointer" }}>
          <img src={logo} className="App-logo" alt="react-logo" />
          <input {...getInputProps()} />
          {isDragActive ? (
            <p>Drop the files here ...</p>
          ) : (
            <p>
              Click the logo to upload to IPFS
            </p>
          )}
        </div>
        <div>
          {ipfsHash !== "" ? (
            <a
              href={`https://ipfs.io/ipfs/${ipfsHash}`}
              target="_blank"
              rel="noopener noreferrer"
            >
              See current user file
            </a>
          ) : (
            "No user file set yet"
          )}
        </div>
      </header>
    </div>
  );
}

export default App;
