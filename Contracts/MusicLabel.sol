//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts@4.9.0/access/Ownable.sol";
import "@api3/contracts/v0.8/interfaces/IProxy.sol";

contract MusicLabel is RrpRequesterV0, Ownable {

    event RequestedUint256(bytes32 indexed requestId);
    event ReceivedUint256(bytes32 indexed requestId, int256 response);

    address public proxyAddress;

    address public airnode;
    address public sponsorWallet;
    bytes32 public endpointId;

    uint256 public returnedResponse;

    string public artistId;

    mapping(bytes32 => bool) public incomingFulfillments;
    mapping(uint256 => bool) public milestonesPaid;
    mapping(string => address) public artistRegistry;

    // Milestones
    uint256[] public milestones = [10, 100, 1000];

    constructor(address _rrpAddress) RrpRequesterV0(_rrpAddress) {}

    // Set our price feed 
    function setProxyAddress(address _proxyAddress) public onlyOwner {
        proxyAddress = _proxyAddress;
    }

    // Register an artist
    function registerArtist(string memory _id, address _address) external onlyOwner {
        artistRegistry[_id] = _address;
    }

    // Setup Airnode Parameters
    function setRequestParameters(
        address _airnode,
        bytes32 _endpointId,
        address _sponsorWallet
    ) external onlyOwner {
        airnode = _airnode;
        endpointId = _endpointId;
        sponsorWallet = _sponsorWallet;
    }

    //The main makeRequest function that will trigger the Airnode request.
    function makeRequest(bytes calldata parameters, string memory _id) external {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointId,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfill.selector,
            parameters
        );
        artistId = _id;
        incomingFulfillments[requestId] = true;
        emit RequestedUint256(requestId);
    }

    // This is the response from the Airnode request
    // It should return with a number of youtube views for that video
    function fulfill(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];
        int256 decodedData = abi.decode(data, (int256));
        returnedResponse = uint256(decodedData);
        payout(returnedResponse, artistId);
        emit ReceivedUint256(requestId, decodedData);
    }

    function readDataFeed() public view returns (uint256, uint256) {
        (int224 value, uint256 timestamp) = IProxy(proxyAddress).read();
        //convert price to UINT256
        uint256 price = uint224(value);
        return (price, timestamp);
    }

    function payout(uint256 _views, string memory _id) internal {
        for (uint256 i = 0; i < milestones.length; i++) {
            uint256 currentMilestone = milestones[i];
            if (_views >= currentMilestone && !milestonesPaid[currentMilestone]) {
                milestonesPaid[currentMilestone] = true;

                // Fetch the current ETH price in USD
                (uint256 price, ) = readDataFeed();

                // Calculate the equivalent amount in ETH for a hundred dollars
                // Note: Assuming price is the price of 1 ETH in USD in wei format (e.g., if 1 ETH = $3000, then price = 3000e18)
                uint256 amountInETHWei = (100e18 * 1 ether) / price;

                // Ensure the contract has enough balance to pay out
                require(address(this).balance >= amountInETHWei, "Insufficient contract balance");

                // Send the calculated amount to the artist
                (bool success, ) = payable(artistRegistry[_id]).call{value: amountInETHWei}("");
                require(success, "Failed payout");

                break;  // Break out of the loop once a milestone is paid
            }
        }
    }

    // Function to withdraw any remaining funds in the contract (for the owner)
    function withdraw() external onlyOwner{
        (bool success, ) = payable(msg.sender).call{value: (address(this).balance)}("");
        require(success, "Failed payout");
    }

    receive () external payable {}
    fallback () external payable {}

}
