# Airnode RRP Requester Tutorial
Run the following command to install all the dependencies:
```
npm install
```

# Part 1 - Deploying the Airnode

## Requirements

- You will need an [Amazon Web Services (AWS)](https://aws.amazon.com) account  before Airnode can be deployed

- You will need [Docker](https://docs.docker.com/get-docker/) installed locally

## Adding your credentials

- Get your AWS IAM Access Keys with Administrator Access policy. You can watch this [video](https://www.youtube.com/watch?v=KngM5bfpttA) if you're not sure how to obtain them.

- Populate the aws.env file with your ``` AWS_ACCESS_KEY_ID ``` and ``` AWS_SECRET_ACCESS_KEY ```

- Under the config directory, look for ```secrets.env``` and add in your ```AIRNODE_WALLET_MNEMONIC```. Make sure you use the same mnemonic that you used to sign in with ChainAPI otherwise it will show your deployment as "inactive" on the ChainAPI's deployments section. </br> 

- Add in your ```LINEA_GOERLI_TESTNET_1_PROVIDER_URL```. You can have a different name for the Provider URL depending on what network you choose during integration. 

- Your secrets file will also have ```HEARTBEAT_URL```, ```HEARTBEAT_ID``` and ```HEARTBEAT_API_KEY``` that is automatically generated by ChainAPI to check if an Airnode is active or not. You can disable it in ```config.json``` but it is not recommended as your deployments on ChainAPI will be marked as “inactive” and limit future opportunities.

- You can add in your ```HTTP_SIGNED_DATA_GATEWAY_API_KEY``` and ``` HTTP_GATEWAY_API_KEY_BETWEEN_30_TO_120_CHARACTERS``` (You can also use the values that are pre-filled by ChainAPI). The HTTP gateway is an optional service that allows authenticated users to make HTTP requests to your deployed Airnode instance. This is used for testing and future services provided by API3 and ChainAPI.

## Deploying the Airnode

- Open a terminal and change directory to where you extracted these files.

- Run the following Docker command based on your current operating system. Follow any prompts or instructions.

- You can more detailed information in the [API3 Deployment Tutorial](https://docs.api3.org/airnode/v0.7/grp-providers/tutorial/) 

#### Windows
```
docker run -it --rm ^
      -v "%cd%:/app/config" ^
      api3/airnode-deployer:0.12.0 deploy
```

#### OSX
```
docker run -it --rm \
      -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) \
      -v "$(pwd):/app/config" \
      api3/airnode-deployer:0.12.0 deploy
```

#### Linux
```
docker run -it --rm \
      -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) \
      -v "$(pwd):/app/config" \
      api3/airnode-deployer:0.12.0 deploy
```

# Part 2 - Coding the Requester Contract and calling the Airnode

## Requirements

- Clone and set up the [Airnode Monorepo](). install and build all the dependencies and packages to be able to access the Airnode CLI.

- Using [Remix IDE](https://remix.ethereum.org) to deploy and call the Requester contract on the Arbitrum Goerli Testnet.

- Wallet with enough ETH to sponsor the ```sponsorWallet```. You can get some from the [Linea Faucet](https://www.infura.io/faucet/linea).

## Encoding the Parameters
- Head on to ```src/encodeParams.js``` and edit it to encode your parameters.
- To get the encoded parameters:
```
node .\src\encodeParams.js
```
## Deploying the Requester

- Compile and Deploy the ```Youtube.sol``` contract on Remix. Select the ```_rrpAddress``` from [here](https://docs.api3.org/reference/airnode/latest/). 
Linea RRP address is currently in the following [repo](https://github.com/api3dao/airnode/blob/master/packages/airnode-protocol/deployments/linea/AirnodeRrpV0.json) ```0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd```

- Derive your ```sponsorWallet``` address using the Airnode CLI.

Note: The ```sponsor-address``` here will be the address of the Requester Contract that you just deployed.
#### Linux:
```
npx @api3/airnode-admin derive-sponsor-wallet-address \
  --airnode-xpub xpub6CUGRUo... \
  --airnode-address 0xe1...dF05s \
  --sponsor-address 0xF4...dDyu9
```

#### Windows:
```
npx @api3/airnode-admin derive-sponsor-wallet-address ^
  --airnode-xpub xpub6CUGRUo... ^
  --airnode-address 0xe1...dF05s ^
  --sponsor-address 0xF4...dDyu9
```

Fund the ```sponsorWallet``` with some test Arbitrum Goerli ETH

- Pass in your ```airnode```, ```endpointID```, ```sponsor``` (The Requester contract itself), ```sponsorWallet``` (derived from the Airnode CLI) and ```parameters``` to call the ```makeRequest``` function.

- Check the latest transaction from the ```sponsorWallet``` and go to its logs. The requested data will be encoded in ```bytes32```.
- You can get the ```returnedResponse``` from the public variables to get the decoded output.

# Part 3 - Setting up the Royalty Payout

- You can get the ```ETH/USD``` price feed from the API3 Marketplace [here](https://market.api3.org/dapis). Once you pick the price feed of your choice, make sure to copy the Proxy Contract Address and set it in the ```setProxyAddress``` function.  

- We must register the artists wallet in order to receive the payout correctly. In order to keep track of each artist registered, we will enter the artists' wallet and the unique Youtube video ID of the specific song to keep those tied together using the ```registerArtist``` function.

- In order to payout the artists, we have to fund the contract with ETH.  We are able to send ETH directly to the contract because we have the ```receive () external payable {}``` catch all function.

- Once all artists are registered and contract funded with ETH, we will want to send out the request to check the view count of our specific artists song. In our
```
node .\src\encodeParams.js
```
file, we will want to update out youtube ID to match our artists song
```
const params = [
   { type: 'string', name: 'part', value: 'statistics' }, 
   { type: 'string', name: 'id', value: 'Jfk6-lZUUvQ' }, 
   { type: 'string', name: '_path', value: 'items.0.statistics.viewCount' },
   { type: 'string', name: '_type', value: 'int256' }
];
```
Once we encode it, it will looking something like this:
```
0x315353535300000000000000000000000000000000000000000000000000000070617274000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000120696400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001605f7061746800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a05f7479706500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000000a7374617469737469637300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b4a666b362d6c5a55557651000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c6974656d732e302e737461746973746963732e76696577436f756e74000000000000000000000000000000000000000000000000000000000000000000000006696e743235360000000000000000000000000000000000000000000000000000
```
We paste this into our ```makeRequest``` function followed by the unique Youtube ID ```Jfk6-lZUUvQ```

This will send out the request and receive the amount of views the video was played and payout the artist accordingly.
