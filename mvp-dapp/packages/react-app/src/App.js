import React, { useCallback, useState, useEffect } from "react";
import { useDropzone } from "react-dropzone";
import IPFS from "ipfs";
import { ethers } from "ethers";
import LearningSession from "./artifacts/LearningSession.json"; // Import ABI
import "./App.css";

// Replace with your deployed contract address
const contractAddress = "0x1234...";

const App = () => {
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [ipfsHash, setIpfsHash] = useState("");
  const [artifactId, setArtifactId] = useState(""); // Artifact ID for adding comments
  const [voteArtifactId, setVoteArtifactId] = useState(""); // Artifact ID for voting
  const [voteValue, setVoteValue] = useState(0); // Vote value: -1, 0, or 1

  const [ipfs, setIpfs] = useState(null);

  useEffect(() => {
    async function initIPFS() {
      const ipfs = await IPFS.create();
      setIpfs(ipfs);
    }
    initIPFS();
  }, []);

  // Initialize contract instance
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const learningSessionContract = new ethers.Contract(contractAddress, LearningSession.abi, signer);

  // Handle file upload (for adding session artifact or comment)
  const onDrop = useCallback(
    async (acceptedFiles) => {
      setLoading(true);
      setErrorMessage("");
      try {
        const files = acceptedFiles.map((file) => ({
          path: file.name + file.path,
          content: file,
        }));

        for await (const result of ipfs.add(files)) {
          setIpfsHash(result.cid.toString());
          if (!artifactId) {
            // Add a new session artifact
            await learningSessionContract.addSessionArtifact(result.cid.toString());
          } else {
            // Add a comment to an existing artifact
            await learningSessionContract.addComment(artifactId, result.cid.toString());
          }
        }
      } catch (error) {
        setErrorMessage(error.message);
      } finally {
        setLoading(false);
      }
    },
    [ipfs, artifactId, learningSessionContract]
  );

  // Handle vote submission
  const submitVote = async () => {
    setLoading(true);
    setErrorMessage("");
    try {
      // Submit the vote to the smart contract
      await learningSessionContract.vote(voteArtifactId, voteValue);
    } catch (error) {
      setErrorMessage(error.message);
    } finally {
      setLoading(false);
    }
  };

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
            <p>Click the logo to upload to IPFS</p>
          )}
        </div>
              <input        type="text"
        placeholder="Artifact ID for adding comment (leave empty for new artifact)"
        value={artifactId}
        onChange={(e) => setArtifactId(e.target.value)}
      />
    </div>
    <div>
      {ipfsHash ? (
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
    <div>
      <input
        type="text"
        placeholder="Artifact ID for voting"
        value={voteArtifactId}
        onChange={(e) => setVoteArtifactId(e.target.value)}
      />
      <select
        value={voteValue}
        onChange={(e) => setVoteValue(parseInt(e.target.value))}
      >
        <option value={-1}>-1 (Downvote)</option>
        <option value={0}>0 (Neutral)</option>
        <option value={1}>1 (Upvote)</option>
      </select>
      <button onClick={submitVote}>Submit Vote</button>
    </div>
    {loading && <div>Loading...</div>}
    {errorMessage && <div className="error">{errorMessage}</div>}
  </header>
</div>
);
};

export default App;

        <div
