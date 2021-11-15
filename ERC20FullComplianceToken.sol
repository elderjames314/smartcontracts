// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

//----------------------------------------------------------

//EIP 20: ERC 20 standard
//https://eips.ethereum.org/EIPS/eip-20

//----------------------------------------------------------

interface ERC20Interface {
    //these are the only mandatory function in ERC20 based token
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns(uint balance);
    function transfer(address to, uint tokens) external  returns(bool success);
    
    //others are optional
    function allowance(address tokenOwner, address spender) external view returns(uint remaining);
    function approve(address spender, uint tokens) external returns(bool success);
    function transferFrom(address from, address to,uint tokends) external returns(bool success);
    
    event Transfer(address indexed from,  address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint value);
}


contract Cryptos is  ERC20Interface {
    //the name that token is called
    string public name = "JAMES";
    //the short or alias of the token
    string public symbol = "ELDERJAMES";
    uint public decimals = 3; //decimal ranging between 0 - 18; 18 is the most preferred
    uint public override totalSupply;
    //the founder of the token.his address will be used
    address public founder;
    //the mapp of the address and value of the holders
    mapping(address => uint) public balances;
    
    //create allowance mapping
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() {
        totalSupply = 10000000000; //total supply to be 1million
        founder = msg.sender; //the founder is the address that deploy the contract.
        //and the address of the founder will hold the total supply.
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view override returns(uint balance) {
        //return the balance of the token owner
        return balances[tokenOwner];
    }
    
    //this function make the token transferable
    //basically it will transfer the value from the owner address
    function transfer(address to, uint token) public override returns(bool success) {
        //check if the owner has enough token to transfer
        //note according to the standard, transfer of zero value must be traeated like normal
        //transfer and fire the transfer event in return.
        require(balances[msg.sender] >= token, "You must have enough token to make transfer");
        //then increase the balance of the recipient with amount sent
        balances[to] += token;
        //decrease the balance of the sender by the token sent
        balances[msg.sender] += token;
    
       //afterthe transder transaction, the function emmit event transfer event
       //this is local log file that is sent to blockchanin.
       emit Transfer(msg.sender, to, token);
       
       //finally
       return true;
    
    }
    
    function allowance(address tokenOwner, address spender) public override view returns(uint) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public override returns(bool success) {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        
        return true;
    }
    
     function transferFrom(address from, address to,uint tokens) public override returns(bool success) {
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         balances[to] +=  tokens;
         
         allowed[from][to] -= tokens;
         
         return true;
     }
}


