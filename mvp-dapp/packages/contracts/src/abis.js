import erc20Abi from "./abis/erc20.json";
import ownableAbi from "./abis/ownable.json";
import ipfsStorage from "./abis/IpfsStorage.json";
import learningSession from "./abis/learningSession.json";

const abis = {
  erc20: erc20Abi,
  ownable: ownableAbi,
  ipfs: ipfsStorage,
  learningSession: learningSession,
};

export default abis;
