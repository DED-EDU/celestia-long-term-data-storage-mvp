import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { addresses, abis } from "@project/contracts";

const ZERO_ADDRESS =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

const useBlockchain = () => {
  const [ipfsHash, setIpfsHash] = useState("");
  const [ipfsContract, setIpfsContract] = useState(null);

  useEffect(() => {
    const initBlockchain = async () => {
      if (!window.ethereum) {
        console.error("No Ethereum provider found.");
        return;
      }
      // Request user to connect wallet
      await window.ethereum.request({ method: "eth_requestAccounts" });

      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        addresses.ipfs,
        abis.ipfs,
        provider
      ).connect(signer);

      setIpfsContract(contract);

      const userAddress = await signer.getAddress();
      const file = await contract.userFiles(userAddress);
      if (file !== ZERO_ADDRESS) setIpfsHash(file);
    };

    initBlockchain();
  }, []);

  const setFile = async (hash) => {
    try {
      if (!ipfsContract) {
        console.error("IPFS Contract is not initialized.");
        return;
      }
      const tx = await ipfsContract.setFile(hash);
      await tx.wait();
      setIpfsHash(hash);
    } catch (error) {
      console.error("Failed to set file:", error);
    }
  };

  return { ipfsHash, setFile };
};

export default useBlockchain;
