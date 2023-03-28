import { useCallback, useEffect, useState } from "react";
import IPFS from "ipfs";

const useIpfs = () => {
  const [node, setNode] = useState(null);
  const [ipfsReady, setIpfsReady] = useState(false);

  useEffect(() => {
    const initIpfs = async () => {
      const ipfsNode = await IPFS.create();
      setNode(ipfsNode);
      setIpfsReady(true);
    };
    initIpfs();
  }, []);

  const uploadFile = useCallback(async (file) => {
    if (!ipfsReady || !node) {
      console.error("IPFS node is not ready.");
      return null;
    }
    try {
      const files = [
        {
          path: file.name + file.path,
          content: file,
        },
      ];
      let resultCid;
      for await (const result of node.add(files)) {
        resultCid = result.cid.toString();
      }
      return resultCid;
    } catch (error) {
      console.error("Failed to upload file to IPFS:", error);
      return null;
    }
  }, [ipfsReady, node]);

  return { ipfsReady, uploadFile };
};

export default useIpfs;

