// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {DeepFiConsumer} from "../src/DeepFiConsumer.sol";
import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract DeepFiConsumerScript is Script {

    function setUp() public {

    }

    function run() public {
        uint256 deployerPrivKey = vm.envUint("PRIV_KEY");

        address fxnsRouter = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
        bytes32 donId = "fun-ethereum-sepolia-1";
        address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        
        string memory source = vm.envString("SOURCE");
        bytes memory secret = "";
        string memory arg = '{"requestData": {"entry_price": ""}}';

        bytes memory exit1 = "0x7377696e675f73686f72745f656e747279";
        bytes memory exit2 = "0x72616e67655f73686f72745f656e747279";

        vm.startBroadcast(deployerPrivKey);

        DeepFiConsumer consumer = new DeepFiConsumer(fxnsRouter, donId, ISwapRouter(swapRouter));
        consumer.setSourceRefs(source, secret, arg);
        consumer.setExits(exit1, exit2);

        vm.stopBroadcast();
    }
}
