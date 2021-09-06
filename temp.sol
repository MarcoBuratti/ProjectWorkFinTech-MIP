pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract AmazonCurrency {
    string  public constant name = "Amazon Currency Token";
    string  public constant symbol = "AMZNCRY";
    uint8 public constant decimals = 18;
    string  private standard = "Amazon Currency Token v1.0";
    uint256 private constant totalSupply = 100000000000000000000000000;
    uint256 private leftSupply = 100000000000000000000000000;
    uint256 private tokenPrice = 312000000000000; // conversione da un dollaro a eth
    address payable private contractOwner;
    
    event Transfer( address indexed _from, address indexed _to, uint256 _value );
    event Approval( address indexed _owner, address indexed _spender, uint256 _value );
    event Bought( address indexed _buyer, uint256 indexed amount );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private allowance;
    mapping(address => CustomerAccount) private customerBalance;
    
    struct CustomerAccount {
        uint256 amount;
        bool spent;
    }
    
    AmazonStock private AmazonStockToken;

    constructor () public {
        balanceOf[address(this)] = totalSupply;
        contractOwner = msg.sender;
        AmazonStockToken = new AmazonStock(address(this));
    }

    function transfer(address _to, uint256 _value) private returns (bool success){
        require(leftSupply >= _value);
        leftSupply -= _value;
        balanceOf[address(this)] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(address(this), _to, _value);
        return true;
    }
    function buy(uint256  _numberOfTokens) payable public {
        require( msg.value == _numberOfTokens * tokenPrice );
        _numberOfTokens = _numberOfTokens * 1000000000000000000;
        transfer(msg.sender, _numberOfTokens);
        //contractOwner.send(msg.value);
        customerBalance[msg.sender].amount += 0;
        customerBalance[msg.sender].spent = false;
        emit Bought(msg.sender, msg.value);
    }
    function pay(uint256 _numberOfTokens) public returns (bool){
        _numberOfTokens = _numberOfTokens * 1000000000000000000;
        require ( balanceOf[msg.sender] >= _numberOfTokens, "you are trying to spend more AMZNCRY than you have!");
        balanceOf[msg.sender] -= _numberOfTokens;
        balanceOf[address(this)] += _numberOfTokens;
        customerBalance[msg.sender].amount += _numberOfTokens;
        customerBalance[msg.sender].spent = true;
        return true;
    }
    
    function requestTransferAmazonStock() public payable {
        require (customerBalance[msg.sender].spent == true, "You must buy some AMZNCRY and spent before request a stock conversion!");
        AmazonStockToken.requestToBuy(msg.sender);
    }
    function requestAmazonStock() public payable returns (bool){
        //require( AmazonStockToken.requestHasBeenMade(msg.sender), "Your request is pending, please wait try later!");
        AmazonStockToken.buy(percentage(customerBalance[msg.sender].amount), msg.sender );
        return true;
    }
    function percentage(uint256 _amount) private returns (uint256) {
        uint256 perc = _amount * 2;
        perc = perc / 100;
        return perc;
    }
    
    function approve(address _spender, uint256 _value) private returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) private returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function getTknPrice() public view returns (uint256) {
        return tokenPrice;
    }
    function requestToken(uint256 _tokenToBuy) public view returns (uint256) {
        uint256 ethAmount;
        ethAmount =  tokenPrice * _tokenToBuy;
        return ethAmount;
    }
    function getMoneyBalance() private view returns (uint256) {
        return address(this).balance;
    }
    function getApiAddressAmzn() public view returns (address){
       return  AmazonStockToken.getApiAddress();
    }
    function getAmazonStockTokenAddress() public view returns (address) {
        return AmazonStockToken.getContractAddressStock();
    }
}

contract AmazonStock {
    string  public constant name = "Amazon Stock Token";
    string  public constant symbol = "AMZNSTK";
    uint8 public constant decimals = 18;
    string  private standard = "Ecommerce Token v1.0";
    uint256 private totalSupply = 100000000000000000000000000;
    uint256 private leftSupply = 100000000000000000000000000;
    uint256 private tokenPrice = 312000000000000; // conversione da un dollaro a eth
    address private contractOwner;

    uint256 private index;
    PriceAMZN private AMAZON;
    uint256 private deadline;
    
    struct AccountData{
        uint256 priceToBuy;
        bool request;
        uint256 requestIndex;
        uint256 chainStartTime;
    }

    event Transfer( address indexed _from, address indexed _to, uint256 _value );
    event Approval( address indexed _owner, address indexed _spender, uint256 _value );
    event Bought( address indexed _buyer, uint256 indexed amount );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private allowance;
    mapping(address => AccountData) public customerData;

    // Crea il token e i valori che definiscono il contratto
    constructor (address _owner) public {
        index = 1;
        balanceOf[address(this)] = totalSupply;
        //contractOwner = 0x0cbdC5cFfE55D6E2dB656123607F78c80Ba86C3D;
        contractOwner = _owner;
        AMAZON = new PriceAMZN();
    }

    function transfer(address _to, uint256 _value) private returns (bool success){
        require(leftSupply >= _value);
        leftSupply -= _value;
        balanceOf[address(this)] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(address(this), _to, _value);
        return true;
    }
    function buy(uint256  _numberOfTokens, address _sender) public {
        require( requestHasBeenMade(_sender), "Your request is pending, please wait try later!");
        //require( msg.value == _numberOfTokens * tokenPrice );
        //_numberOfTokens = _numberOfTokens ;
        transfer(_sender, _numberOfTokens);
        //contractOwner.send(msg.value);
        //emit Bought(msg.sender, msg.value);
        customerData[_sender].priceToBuy = getAMZNprice(_sender);
        customerData[_sender].request = true;
    }
    function requestToBuy(address _sender) public {
        AMAZON.requestPrice();
        deadline = now + (1 * 3 minutes);
        customerData[_sender] = AccountData(0, false, index, deadline);
        index += 1;
    }
    /*function requestToPay() public returns (string memory){
        require( now > customerData[msg.sender].chainStartTime );
        return "kek";
    }*/
    function requestToken(uint256 _tokenToBuy) public view returns (uint256) {
        uint256 ethAmount;
        ethAmount =  tokenPrice * _tokenToBuy;
        return ethAmount;
    }
    function approve(address _spender, uint256 _value) private returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) private returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function requestHasBeenMade(address _requestID) private view returns (bool) {
        uint256 indexID = customerData[_requestID].requestIndex;
        return AMAZON.getBoolean(indexID);
    }
    function getAMZNprice(address _requestID) private view returns (uint256){
        uint256 indexID = customerData[_requestID].requestIndex;
        return AMAZON.getPriceAMZN(indexID);
    }
    function getApiAddress() public view returns (address){
        return AMAZON.getContractAddress();
    }
    function getTknPrice() public view returns (uint256) {
        return tokenPrice;
    }
    function getMoneyBalance() private view returns (uint256) {
        return address(this).balance;
    }
    function getContractAddressStock() public view returns (address){
        return address(this);
    }
}

contract PriceAMZN is ChainlinkClient {
    using Chainlink for Chainlink.Request;
  
    uint256 private price;
    uint256 private requestIndex;
    uint256 [10] private priceToBuy;
    bool [10] private requests;

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
        requestIndex = 1;
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
        priceToBuy[requestIndex] = _price;
        requests[requestIndex] = true;
        requestIndex += 1;
    }
    
    function getBoolean(uint256 _indiceRichiesta) public view returns (bool){
         return requests[_indiceRichiesta];
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