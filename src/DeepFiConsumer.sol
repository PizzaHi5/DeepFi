// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {TransferHelper} from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import {DeepVariables} from "./interfaces/DeepVariables.sol";

/**
 * @title Chainlink Functions example on-demand consumer contract example
 */
contract DeepFiConsumer is FunctionsClient, AutomationCompatibleInterface, ConfirmedOwner, DeepVariables {
  using FunctionsRequest for FunctionsRequest.Request;

  bytes32 public donId; // DON ID for the Functions DON to which the requests are sent

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;

  uint256 public immutable interval;
  uint256 public lastTimeStamp;
  string private sourceScript;
  bytes private encryptedSecretsRef;

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

  function setSourceRef(string calldata _source, bytes calldata encryptedSecRef) external onlyOwner {
    sourceScript = _source;
    encryptedSecretsRef = encryptedSecRef;
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

    executeResponse(parseResponse(response));
  }

  //parse 32 bytes into uniswap actions
  function parseResponse(bytes memory response) internal view returns (ISwapRouter.ExactInputSingleParams memory params) {
    //Change addresses/uint96 into compressed data types
    (bool isMakingSwap, address tokenIn, address tokenOut, uint96 amountIn) = abi.decode(response, (bool,address,address,uint96));

    //parse tokenIn into token address
    //parse tokenOut into token address

    //fetch price from appropriate feed (list in DeepVariables)
    (,int256 price,,,) = linkMaticFeed.latestRoundData();

    if(isMakingSwap) {
      params = ISwapRouter.ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: uint256(price),
        sqrtPriceLimitX96: 0
      });
    }
  }

  function executeResponse(ISwapRouter.ExactInputSingleParams memory params) internal {
    //buy eth

    //buy matic

    //buy link

    //buy usd

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
      if ((block.timestamp - lastTimeStamp) > interval) {
        lastTimeStamp = block.timestamp;
        __sendRequest(getScript(), FunctionsRequest.Location.DONHosted, getSecRef(), 1001, 300000);
      }
  }

  function __sendRequest(
    string memory source,
    FunctionsRequest.Location secretsLocation,
    bytes memory encryptedSecretsReference,
    uint64 subscriptionId,
    uint32 callbackGasLimit
  ) internal onlyOwner {
    FunctionsRequest.Request memory req; // Struct API reference: https://docs.chain.link/chainlink-functions/api-reference/functions-request
    req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source);
    req.secretsLocation = secretsLocation;
    req.encryptedSecretsReference = encryptedSecretsReference;

    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, donId);
  }

  function getScript() public view returns (string memory) {
    return sourceScript;
  }

  function getSecRef() public view returns (bytes memory) {
    return encryptedSecretsRef;
  }
}