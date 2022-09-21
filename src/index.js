import { ethers } from "./lib/ethers.js";
import SolverTrampoline from "../contracts/build/SolverTrampoline.json" assert {
  type: "json",
};

const provider = new ethers.providers.JsonRpcProvider(
  `https://mainnet.infura.io/v3/${Deno.env.get("INFURA_PROJECT_ID")}`,
);

const settlement = new ethers.Contract(
  "0x9008D19f58AAbD9eD0D60971565AA8510560ab41",
  [
    `function settle(
      address[] tokens,
      uint256[] clearingPrices,
      (
        uint256 sellTokenIndex,
        uint256 buyTokenIndex,
        address receiver,
        uint256 sellAmount,
        uint256 buyAmount,
        uint32 validTo,
        bytes32 appData,
        uint256 feeAmount,
        uint256 flags,
        uint256 executedAmount,
        bytes signature
      )[] trades,
      (
        address target,
        uint256 value,
        bytes callData
      )[][3] interactions
    )`,
    `function authenticator() view returns (address)`,
  ],
  provider,
);

const trampoline = new ethers.Contract(
  "0x7777777777777777777777777777777777777777",
  SolverTrampoline.abi,
  provider,
);
trampoline.code = await provider.call({
  data: ethers.utils.solidityPack(
    ["bytes", "bytes"],
    [
      `0x${SolverTrampoline.bin}`,
      trampoline.interface.encodeDeploy([settlement.address]),
    ],
  ),
});

function solverSlot(address) {
  return ethers.utils.solidityKeccak256(
    ["uint256", "uint256"],
    [address, 1],
  );
}
function slotNumber(num) {
  return ethers.utils.solidityPack(["uint256"], [num]);
}

const solver = new ethers.Wallet(ethers.utils.id("moo"), provider);
const emptySolution = settlement.interface.encodeFunctionData("settle", [
  [],
  [],
  [],
  [[], [], []],
]);

const { chainId } = await provider.getNetwork();
const { r, s, v } = ethers.utils.splitSignature(
  await solver._signTypedData(
    { chainId, verifyingContract: trampoline.address },
    {
      Solution: [
        { type: "bytes", name: "solution" },
        { type: "uint256", name: "nonce" },
      ],
    },
    {
      solution: emptySolution,
      nonce: 1337,
    },
  ),
);

const result = await provider.send("eth_call", [
  {
    from: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    to: trampoline.address,
    data: trampoline.interface.encodeFunctionData("settle", [
      emptySolution,
      r,
      s,
      v,
    ]),
  },
  "latest",
  {
    [trampoline.address]: {
      code: trampoline.code,
      stateDiff: {
        [slotNumber(0)]: slotNumber(1337),
      },
    },
    [await settlement.authenticator()]: {
      stateDiff: {
        [solverSlot(trampoline.address)]: slotNumber(1),
        [solverSlot(solver.address)]: slotNumber(1),
      },
    },
  },
]);

if (result !== "0x") {
  throw new Error(`unexpected result ${result}`);
}

console.log("OK");
