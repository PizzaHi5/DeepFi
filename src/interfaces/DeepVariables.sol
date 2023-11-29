// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

// this is setup for mumbai 11/28/23
contract DeepVariables {
    ISwapRouter public immutable swapRouter;
    uint24 public constant poolFee = 3000;

    //chainlink pricefeeds in mumbai
    address public linkMaticFeed = 0x12162c3E810393dEC01362aBf156D7ecf6159528;
    address public linkUsdFeed = 0x1C2252aeeD50e0c9B64bDfF2735Ee3C932F5C408;
    address public ethUsdFeed = 0x0715A7794a1dc8e42615F059dD6e406A6594651A;

    //token addresses in mumbai
    address public constant WETH = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
    address public constant USDC = 0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97;
    address public constant LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    constructor (ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }
}