// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {TransferHelper} from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import {IERC20} from "@openzeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {DeepVariables} from "./interfaces/DeepVariables.sol";

/**
 * @title Chainlink Functions example on-demand consumer contract example
 */
contract DeepFiConsumer is FunctionsClient, AutomationCompatibleInterface, ConfirmedOwner, DeepVariables {
  using FunctionsRequest for FunctionsRequest.Request;

  event StringCheck(string[] diditwork);
  event Action(bool isBuying);

  bytes32 public donId; // DON ID for the Functions DON to which the requests are sent

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;

  uint256 public immutable interval;
  uint256 public lastTimeStamp;

  string private sourceScript;
  bytes private encryptedSecretsRef;
  string private arg; //args must be known in advance, cannot do dynamic string arrays in storage
  bytes private s_exit1;
  bytes private s_exit2;

  uint256 s_lastSwappedAmount;

  constructor(address router, bytes32 _donId, ISwapRouter _swapRouter) 
    FunctionsClient(router) ConfirmedOwner(msg.sender) DeepVariables(_swapRouter) {
    donId = _donId;
  }

  /**
   * @notice Set the DON ID
   * @param newDonId New DON ID
   */
  function setDonId(bytes32 newDonId) external onlyOwner {
    donId = newDonId;
  }

  function setSourceRefs(string calldata _source, bytes calldata encryptedSecRef, string calldata _arg) external onlyOwner {
    sourceScript = _source;
    encryptedSecretsRef = encryptedSecRef;
    arg = _arg;
  }

  function setExits(bytes calldata exit1, bytes calldata exit2) external onlyOwner {
    s_exit1 = exit1;
    s_exit2 = exit2;
  }

  /**
   * @notice Triggers an on-demand Functions request using remote encrypted secrets
   * @param source JavaScript source code
   * @param secretsLocation Location of secrets (only Location.Remote & Location.DONHosted are supported)
   * @param encryptedSecretsReference Reference pointing to encrypted secrets
   * @param args String arguments passed into the source code and accessible via the global variable `args`
   * @param bytesArgs Bytes arguments passed into the source code and accessible via the global variable `bytesArgs` as hex strings
   * @param subscriptionId Subscription ID used to pay for request (FunctionsConsumer contract address must first be added to the subscription)
   * @param callbackGasLimit Maximum amount of gas used to call the inherited `handleOracleFulfillment` method
   */
  function sendRequest(
    string calldata source,
    FunctionsRequest.Location secretsLocation,
    bytes calldata encryptedSecretsReference,
    string[] calldata args,
    bytes[] calldata bytesArgs,
    uint64 subscriptionId,
    uint32 callbackGasLimit
  ) external onlyOwner {
    FunctionsRequest.Request memory req; // Struct API reference: https://docs.chain.link/chainlink-functions/api-reference/functions-request
    req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source);
    req.secretsLocation = secretsLocation;
    req.encryptedSecretsReference = encryptedSecretsReference;
    if (args.length > 0) {
      req.setArgs(args);
    }
    if (bytesArgs.length > 0) {
      req.setBytesArgs(bytesArgs);
    }
    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, donId);
  }

  /**
   * @notice Store latest result/error
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    s_lastResponse = response;
    s_lastError = err;
    bytes memory exit1 = "0x72616e67655f73686f72745f656e747279";
    bytes memory exit2 = "0x7377696e675f73686f72745f656e747279";
    //buy WETH if response is "swing_short_entry " or "range_short_entry"
    if(comapreBytes(response, exit1) &&
       comapreBytes(response, exit2)
    ) {
      //buying WETH with USDC
      emit Action(true);
      executeResponse(parseResponse(response, true));
    } else {
      //selling WETH for USDC
      emit Action(false);
      executeResponse(parseResponse(response, false));
    }
  }

  function comapreBytes(bytes memory a, bytes memory b) public pure returns (bool) {
    for (uint i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
          return false;
      }
    }
    return true;
  }

  //parse 32 bytes into uniswap action(s)
  function parseResponse(bytes memory response, bool isBuyingEth) internal returns (ISwapRouter.ExactInputSingleParams memory params) {
    //fetch price from appropriate feed (list in DeepVariables)
    (,int256 price,,,) = ethUsdFeed.latestRoundData();

    if(isBuyingEth) {
      //buying WETH
      uint256 balance = IERC20(USDC).balanceOf(address(this));
      IERC20(USDC).approve(address(swapRouter), balance);
      params = ISwapRouter.ExactInputSingleParams({
        tokenIn: USDC,
        tokenOut: WETH,
        fee: poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: balance,
        amountOutMinimum: uint256(price),
        sqrtPriceLimitX96: 0
      });
    } else {
      //selling WETH
      uint256 balance = IERC20(WETH).balanceOf(address(this));
      IERC20(WETH).approve(address(swapRouter), balance);
      params = ISwapRouter.ExactInputSingleParams({
        tokenIn: WETH,
        tokenOut: USDC,
        fee: poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: balance,
        amountOutMinimum: uint256(price),
        sqrtPriceLimitX96: 0
      });
    }
  }

  function executeResponse(ISwapRouter.ExactInputSingleParams memory params) internal {
    s_lastSwappedAmount = swapRouter.exactInputSingle(params);
  }

  function checkUpkeep(
        bytes calldata /* checkData */
    )
      external
      view
      override
      returns (bool upkeepNeeded, bytes memory /* performData */)
  {
    upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
  }

  function performUpkeep(bytes calldata /* performData */) external override {
    // if ((block.timestamp - lastTimeStamp) > interval) {
    //   lastTimeStamp = block.timestamp;
    //   __sendRequest(
    //     sourceScript, 
    //     FunctionsRequest.Location.DONHosted, 
    //     encryptedSecretsRef,
    //     arg,
    //     1001, 
    //     300000
    //   );
    // }
  }

  function updateConsumer(bytes calldata source) external {
    __sendRequest(
      string(source), 
      1001, 
      300000
    );
  }

  //does not have string args or bytes args
  function __sendRequest(
    string calldata source,
    uint64 subscriptionId,
    uint32 callbackGasLimit
  ) internal onlyOwner {
    FunctionsRequest.Request memory req; // Struct API reference: https://docs.chain.link/chainlink-functions/api-reference/functions-request
    req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source);
    req.secretsLocation = FunctionsRequest.Location.Inline;
    //req.encryptedSecretsReference = encryptedSecretsReference;

    // bytes memory str = bytes(argIn);
    // if(str.length != 0) {
    //   string[] memory myArray = new string[](1); 
    //   myArray[0] = argIn;
    //   req.setArgs(myArray);
    //   emit StringCheck(myArray);
    // }

    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, donId);
 }

  receive() external payable {}
}