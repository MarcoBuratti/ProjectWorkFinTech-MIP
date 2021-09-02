pragma solidity ^0.6.0;

import "./PriceAMZN.sol";

contract EcommToken {
    string  public constant name = "Ecommerce Token";
    string  public constant symbol = "ECTK";
    uint8 public constant decimals = 18;
    string  private standard = "Ecommerce Token v1.0";
    uint256 private totalSupply = 100000000000000000000000000; // 100 milioni di token disponibili
    uint256 private leftSupply = 100000000000000000000000000;
    uint256 private tokenPrice = 312000000000000; // conversione da un dollaro a eth
    address payable private contractOwner;
    //address _AMZNChainLink
    //PriceAMZN private AMAZON;
    address private AmazonContract;
    
    address [10] private whoBuy;
    uint256 [10] private whatPrice;
    uint256 private index;
    uint256 private price;

    event Transfer( address indexed _from, address indexed _to, uint256 _value );
    event Approval( address indexed _owner, address indexed _spender, uint256 _value );
    event Bought( address indexed _buyer, uint256 indexed amount );
    
    mapping(address => uint256) private balanceOf;
    mapping(address => mapping(address => uint256)) private allowance;
    

    // Crea il token e assegna alle variabili "name", "symbol" e "totalSupply"
    // i loro valori che definiscono il contratto
    constructor () public {
        index = 0;
        balanceOf[address(this)] = totalSupply;
        contractOwner = msg.sender;
    }

    // Funzione per trasferire i token a un indirizzo
    // è richiesto solo che il balance del mittente sia superiore a quanto vuole trasferire
    function transfer(address _to, uint256 _value) private returns (bool success){   
        require(leftSupply >= _value);
        leftSupply -= _value;
        balanceOf[address(this)] = _value;
        balanceOf[_to] += _value;
        emit Transfer(address(this), _to, _value);
        return true;
    }

    function requestToBuy() public {
        PriceAMZN AMAZON = PriceAMZN(AmazonContract);
        AMAZON.requestPrice();
    }
    
    function buy(uint256  _numberOfTokens) payable public {
        require( msg.value == _numberOfTokens * tokenPrice, "Please Insert the right amount of Ether" );
        _numberOfTokens = _numberOfTokens * 1000000000000000000;
        transfer(msg.sender, _numberOfTokens);
        emit Bought(msg.sender, msg.value);
        //contractOwner.send(msg.value);
        //price = getAMZNprice();
        //whoBuy[index] = msg.sender;
        //whatPrice[index] = price;
        //index += 1;
    }
    
    
    function requestTokenPriceToBuy(uint256 _tokenToBuy) public view returns (uint256) {
        uint256 ethAmount;
        //ethAmount = _tokenToBuy * 1000000000000000000;
        //ethAmount = ethAmount / 3200;
        ethAmount =  tokenPrice * _tokenToBuy;
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
    
    function getAMZNprice() public view returns (uint256){
        require(msg.sender == contractOwner, "You are NOT the Contract owner!");
        PriceAMZN AMAZON = PriceAMZN(AmazonContract);
        uint256 pr = AMAZON.getPriceAMZN();
        return pr;
    }
    
    function setAMZNaddress(address _AmazonContract) public {
        require(msg.sender == contractOwner, "You are NOT the Contract owner!");
        AmazonContract = _AmazonContract;
    }
    
    function getTknPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function getMoneyBalance() public view returns (uint256) {
        require(msg.sender == contractOwner, "You are NOT the Contract owner!");
        return address(this).balance;
    }

    function getApiAddress() public view returns (address){
        require(msg.sender == contractOwner, "You are NOT the Contract owner!");
        PriceAMZN AMAZON = PriceAMZN(AmazonContract);
        address _addressApi = AMAZON.getContractAddress();
        return _addressApi;
    }
}
