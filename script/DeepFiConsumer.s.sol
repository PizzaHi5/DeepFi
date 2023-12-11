// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {DeepFiConsumer} from "../src/DeepFiConsumer.sol";
import {DeepVariables} from "../src/interfaces/DeepVariables.sol";
import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {IFunctionsSubscriptions} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsSubscriptions.sol";
import {IERC20} from "@openzeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeepFiConsumerScript is Script {

    function setUp() public {

    }

    function run() public {
        uint256 deployerPrivKey = vm.envUint("PRIV_KEY");

        address fxnsRouter = 0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C;
        bytes32 donId = "fun-polygon-mumbai-1";
        address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        
        string memory source = "";
        bytes memory secret = "";
        string memory arg = "{\"entry_price\": \"\"}";

        bytes memory exit1 = "0x7377696e675f73686f72745f656e747279"; 
        bytes memory exit2 = "0x72616e67655f73686f72745f656e747279";
        address usdc = 0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97;
        address weth = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;

        vm.startBroadcast(deployerPrivKey);

        DeepFiConsumer consumer = new DeepFiConsumer(fxnsRouter, donId, ISwapRouter(swapRouter));
        consumer.setSourceRefs(source, secret, arg);
        consumer.setExits(exit1, exit2);
        IFunctionsSubscriptions(fxnsRouter).addConsumer(1001, address(consumer));
        IERC20(usdc).transfer(address(consumer), 100);
        IERC20(weth).transfer(address(consumer), 100);
        consumer.updateConsumer(bytes(vm.envString("SOURCE")));

        vm.stopBroadcast();
    }
}
