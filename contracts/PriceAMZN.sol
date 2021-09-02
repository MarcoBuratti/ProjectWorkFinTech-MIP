pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
//import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/ChainlinkClient.sol";

contract PriceAMZN is ChainlinkClient {
    using Chainlink for Chainlink.Request;
  
    uint256 private price;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    address private buyerAddress;
    
    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel   
     * Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    constructor() public {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 100 (to remove decimal places from data).
     */
    function requestPrice() public {
        
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("get", string(abi.encodePacked("https://api.finage.co.uk/last/trade/stock/AMZN?apikey=API_KEY85G0HUQUCE3BIF6PVC8Z3TW7VB7AMODK")));

        request.add("path", "price");
        
        // Multiply the result by 100 to remove decimals
        int timesAmount = 100;
        request.addInt("times", timesAmount);
        
        // Sends the request
        sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        price = _price;
    }

    // function withdrawLink() external {}
    function withdrawLink() public {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
    
    function getContractAddress() public view returns (address){
        return address(this);
    }
    
    function getPriceAMZN() public view returns (uint256){
        return price;
    }
    
}
