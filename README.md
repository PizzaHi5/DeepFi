# Backstory

## Inspiration
We were inspired by Chainlink Function and automation to create a proof-of-concept trading bot that utilizes an off-chain API that trades ETH.

## What it does
Our POC utilizes Chainlink automation to trigger a call on a daily timeframe to a solidity contract that uses Chainlink function to call an off-chain API. This API returns trading signals - both LONG and SHORT trades - based on the ETH daily closing price. The API implements two trading strategies. A swing and a momentum trading strategies. 

## How we built it
We started with the Chainlink Functions tutorial calling chat-gpt. We then modified it to call our trading API. Instead of using Javascript to interact with the Chainlink Function consumer, we moved this logic inside a solidity contract. We pass the Javascript to be executed by Chainlink Functions as a parameter to that contract. 

## Challenges we ran into
- Passing the Javascript code into the contract.
- Creating and deploying the API. 
- The development and unit testing cycle was slow because of the multiple steps required.
- Difficulty debugging the code. We had to do multiple deployments in order to isolate issues. 

## Accomplishments that we're proud of
We have a fully functional POC that can be extended with more functionality.

## What we learned
How to use Chainlink Functions and automation in a real life use case. 
Initially, we were planning on using chat-gpt to analyze the ETH closing price and come back with a trading signal. However, we quickly realized that this was feasible. So we pivoted to using chat-gpt to create the trading strategies. We then developed python scripts to implement the strategies and expose them as a callable API using HTTP REST.

## What's next for DeepFi
Now that we have a working end-to-end POC. We can add the following:
- Implement the trading signals on-chain.
- Add more trading strategies.
- Add the ability to return strategy exit signals based on the entry price. This will require passing parameters to the off-chain API.
- Look into training our own trading model using chat-gpt.

# Guide to Use:
```
forge install
```
- Setup .env

    MUMBAI_RPC_URL

    PRIV_KEY 

    MUMBAISCAN_API_KEY

    SOURCE

- Create Chainlink Functions Subscription
- Put the subId in DeepFiConsumer.s.sol -> addConsumer function (I used 1001)
- Since the api trades mumbai USDC and WETH, ensure your wallet is funded with both. Addresses in DeepFiConsumer.s.sol.
```
forge script script/DeepFiConsumer.s.sol:DeepFiConsumerScript --broadcast --verify -vvvv --rpc-url <your api url>
```
### Note: Ensure your private key is the same private key used to deploy your Chainlink Functions Subscription

## Deployed Contracts

Deployed DeepFi Functions Consumer:
https://mumbai.polygonscan.com/address/0xCB6d1C1e19a73AB55d798F9004A3F5AA4Dac2Dd2

Upkeep Contract:
https://automation.chain.link/mumbai/102128371115149470353784198879861917573356993803611867725044921447112623745334

Functions Subscription:
https://functions.chain.link/mumbai/1001

Source code for chainlink function calls:
https://github.com/PizzaHi5/DeepFi-GPT/blob/main/source.js


