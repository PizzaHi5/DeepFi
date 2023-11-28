// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

// this is setup for mumbai 11/28/23
interface DeepVariables {
    ISwapRouter public immutable swapRouter;
    uint24 public constant poolFee = 3000;

    //chainlink pricefeeds in mumbai
    address public linkMaticFeed = 0x12162c3E810393dEC01362aBf156D7ecf6159528;
    address public linkUsdFeed = 0x1C2252aeeD50e0c9B64bDfF2735Ee3C932F5C408;
    address public ethUsdFeed = 0x0715A7794a1dc8e42615F059dD6e406A6594651A;

    //token addresses in mumbai
    address public constant ETH = 0x0;
    address public constant USDC = 0x0;
    address public constant LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
}