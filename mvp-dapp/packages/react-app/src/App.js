import React, { useCallback, useState } from "react";
import { useDropzone } from "react-dropzone";
import { useIpfs } from "./hooks/useIpfs";
import { useBlockchain } from "./hooks/useBlockchain";

import logo from "./ethereumLogo.png";
import spinner from "./spinner.gif";
import "./App.css";

const App = () => {
  const [loading, setLoading] = useState(false);
  const { ipfs, initIpfs } = useIpfs();
  const { ipfsHash, setFile, readCurrentUserFile } = useBlockchain();
  const [errorMessage, setErrorMessage] = useState("");

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
          await setFile(result.cid.toString());
        }
      } catch (error) {
        setErrorMessage(error.message);
      } finally {
        setLoading(false);
      }
    },
    [ipfs, setFile]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    multiple: false,
    onDrop,
  });

  return (
    <div className="App">
      <header className="App-header">
        <div {...getRootProps()} className="dropzone">
          <input {...getInputProps()} />
          <img src={logo} className="App-logo" alt="react-logo" />
          {isDragActive ? (
            <p>Drop the file here to upload to IPFS</p>
          ) : (
            <p>Click or drag a file here to upload to IPFS</p>
          )}
        </div>
        {loading ? (
          <div>
            <img src={spinner} className="spinner" alt="Loading" />
            <p>Uploading file...</p>
          </div>
        ) : (
          <div className="file-info">
            {ipfsHash ? (
              <a
                href={`https://ipfs.io/ipfs/${ipfsHash}`}
                target="_blank"
                rel="noopener noreferrer"
              >
                See current user file
              </a>
            ) : (
              <p>No user file set yet</p>
            )}
          </div>
        )}
        {errorMessage && <div className="error">{errorMessage}</div>}
      </header>
    </div>
  );
};

export default App;
