pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
//import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/ChainlinkClient.sol";

contract EcommToken {
    string  public constant name = "Ecommerce Token";
    string  public constant symbol = "ECTK";
    uint8 public constant decimals = 18;
    string  private standard = "Ecommerce Token v1.0";
    uint256 private totalSupply = 10000000000000000000;
    uint256 private leftSupply = 10000000000000000000;
    uint256 public tokenPrice = 312000000000000; // conversione da un dollaro a eth
    address payable private contractOwner;
    //address _AMZNChainLink
    //PriceAMZN private AMAZON;
    address private AmazonContract;
    uint256 public stockPrice;
    
    address [10] public whoBuy = [0x0000000000000000000000000000000000000000];
    uint256 [10] public whatPrice = [0];
    uint256 public index = 0;
    uint256 public price;
    
    struct AccountData{
        uint256 priceToBuy;
        bool request;
        uint256 requestIndex;
    }

    event Transfer( address indexed _from, address indexed _to, uint256 _value );
    event Approval( address indexed _owner, address indexed _spender, uint256 _value );
    event Bought( address indexed _buyer, uint256 indexed amount );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private allowance;
    mapping(address => AccountData) public customerData;

    // Crea il token e i valori che definiscono il contratto
    constructor () public {
        index = 0;
        balanceOf[address(this)] = totalSupply;
        contractOwner = 0x0cbdC5cFfE55D6E2dB656123607F78c80Ba86C3D;
    }

    // Funzione per trasferire i token a un indirizzo
    // è richiesto solo che il balance del mittente sia superiore a quanto vuole trasferire
    function transfer(address _to, uint256 _value) private returns (bool success){
        
        require(leftSupply >= _value);
        //whoPaid[msg.sender] = msg.value;
        //contractOwner.send(msg.value);
        leftSupply -= _value;
        balanceOf[address(this)] = _value;
        balanceOf[_to] += _value;
        emit Transfer(address(this), _to, _value);
        return true;

    }

    function buy(uint256  _numberOfTokens) payable public {
        require( requestHasBeenMade(msg.sender), "Your request is pending, please wait try later!");
        require( msg.value == _numberOfTokens * tokenPrice );
        //uint256 amountTobuy = msg.value;
        require(msg.value > 0, "You need to send some Ether");
        //require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        _numberOfTokens = _numberOfTokens * 1000000000000000000;
        transfer(msg.sender, _numberOfTokens);
        //contractOwner.send(msg.value);
        emit Bought(msg.sender, msg.value);
        customerData[msg.sender].priceToBuy = getAMZNprice(msg.sender);
        customerData[msg.sender].request = true;
    }
    
    function requestToBuy() public {
        PriceAMZN AMAZON = PriceAMZN(AmazonContract);
        AMAZON.requestPrice(index);
        customerData[msg.sender] = AccountData(0, false, index);
        index += 1;
    }
    
    function requestHasBeenMade(address _requestID) private returns (bool) {
        uint256 indexID = customerData[_requestID].requestIndex;
        PriceAMZN AMAZON = PriceAMZN(AmazonContract);
        return AMAZON.getBoolean(indexID);
    }
    
    function getAMZNprice(address _requestID) public view returns (uint256){
        uint256 indexID = customerData[_requestID].requestIndex;
        PriceAMZN AMAZON = PriceAMZN(AmazonContract);
        return AMAZON.getPriceAMZN(indexID);
    }
    
    function requestToken(uint256 _tokenToBuy) public view returns (uint256) {
        uint256 ethAmount;
        ethAmount = _tokenToBuy * 1000000000000000000;
        ethAmount = ethAmount / 3200;
        return ethAmount;
    }
    
    // Approva il trasferimento a un inidirizzo "xy"
    function approve(address _spender, uint256 _value) private returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Funzioni che servono a "delegre" il trasferimento dei token
    function transferFrom(address _from, address _to, uint256 _value) private returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
    
    function setAMZNaddress(address _AmazonContract) public {
        AmazonContract = _AmazonContract;
    }
    function getTknPrice() public view returns (uint256) {
        return tokenPrice;
    }
    function getMoneyBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract PriceAMZN is ChainlinkClient {
    using Chainlink for Chainlink.Request;
  
    uint256 private price;
    uint256 private requestIndex;
    uint256 [10] private priceToBuy;
    bool [10] private request;

    //uint256 private indiceRichiesta;
    //uint256 [10] public whatPrice = [0];
    //bool [10] private isRecieved = [false];
    //uint256 public index = 0;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    address private buyerAddress;
    
    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    constructor() public {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
        requestIndex = 0;
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 100 (to remove decimal places from data).
     */
    function requestPrice(uint256 _index) public {
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
        priceToBuy[requestIndex] = _price;
        request[requestIndex] = true;
        requestIndex += 1;
    }
    
    function getBoolean(uint256 _indiceRichiesta) public view returns (bool){
         return request[_indiceRichiesta];
    }
    function getPriceAMZN(uint256 _indiceRichiesta) public view returns (uint256){
        return priceToBuy[_indiceRichiesta];
    }

    // function withdrawLink() external {}
    function withdrawLink() public {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
    
    function getContractAddress() public view returns (address){
        return address(this);
    }
    
}
