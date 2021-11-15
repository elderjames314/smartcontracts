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


contract OkunCryptos is  ERC20Interface {
    //the name that token is called
    string public name = "OKUN";
    //the short or alias of the token
    string public symbol = "ELDER";
    uint public decimals = 0; //decimal ranging between 0 - 18; 18 is the most preferred
    uint public override totalSupply;
    //the founder of the token.his address will be used
    address public founder;
    //the mapp of the address and value of the holders
    mapping(address => uint) public balances;
    
    //create allowance mapping
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() {
        totalSupply = 1000000; //total supply to be 1million
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
    function transfer(address to, uint token) public virtual override returns(bool success) {
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
    
     function transferFrom(address from, address to,uint tokens) public virtual override returns(bool success) {
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         balances[to] +=  tokens;
         
         allowed[from][to] -= tokens;
         
         return true;
     }
}

//ICO can be seen a service for capital for startup for company that offer investors some amount new cryptocurrency
//in exhange for well knowm token such as bitcoin or ethereum
//our ICO will accept ETH in  exchange for ELDER token
//investor will send ETH to ICO smart contract address and in return will get ELDER equavalent token
//there will be externally owned address(EOA) that receive the ETH the deposit sent
//the minimum investment is 0.001 ETH and max is 5 ETH
//ICO hardcap is 300 ETH
//there will start and end of ICO
//locking up token - ELDER token will be tradeable after sometimes
//incase of emergency or hacked, admin can stop ICO or change EOA
//typically ICO can be in state such as BeforeState, Running, AfterEnd and Halted
contract ElderICO is OkunCryptos {
    //ico will have admin... that can start the ICO or halt if gets compromised or change the admin address 
    address public admin;
    //the external owned address(EOA) that will get the ETH of the investors 
    //it is safer that way and the address must be payable so that it can receive ETH
    address payable public deposit;
    //set the token price
    uint tokenPrice = 0.001 ether; //that is with 1ETH, the investor will get 1000 ELDER token OR 1 ELDER == 0.001 ETH
    //the max eth that we want from investors, and when this amount is reached, the ICO will automatically end 
    uint public hardcap = 300 ether;
    //the variable that will hold the total amount sent by investors to the ICO 
    uint public raisedAmount;
    //the time to start ICO 
    //uint public saleStart = block.timestamp + 3600; //start in three days time
    //but we want our ICO to start immediatelly
    uint public saleStart = block.timestamp;
    //the time that our ICO will end 
    //in our case we want our ICO to end in one week time 
    uint public saleEnd = block.timestamp + 604800;
    //it is normal to make token transfer in some time after the sale end 
    uint public tokenTradeStart = saleEnd + 604800; // that is token will be transfered to the investors a week after the token end
    //the maximum that an investors can contribute is 5 ether 
    uint public maxInvestment = 5 ether;
    //the minimum investment 
    uint public minInvestment = 0.1 ether;
    //declare a variable to hold possible state of the ICO 
    enum State {BEFORESTART, RUNNING, AFTEREND, HALTED}
    State public icoState;
    
    
    //initialize 
    constructor(address payable _deposit) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.BEFORESTART;
    }
    
    //admin can stop the ICO incase it gets compromised or hacked  or incase there is an emmergency
    modifier onlyAdmin() {
        require(msg.sender ==  admin);
        _;
    }
    
    //stop or halt the ICO 
    function halt() public onlyAdmin {
        icoState = State.HALTED;
    }
    
    //admin can also restart or resume the ICO 
    function resume() public onlyAdmin {
        icoState = State.RUNNING;
    }
    
    //incase the ICO deposit address get hacked or complicated.
    //admin can change the deposit address 
    function changeDepositAddress(address payable newDeposit) public {
        deposit = newDeposit;
    }
    
    //get the ICO state 
    function getCurrentState() public view returns(State) {
        if(icoState == State.HALTED) {
            return State.HALTED;
        }else if (block.timestamp < saleEnd) {
            return State.BEFORESTART;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.RUNNING;
        }else {
            return State.AFTEREND;
        }
    }
    
    //it will be proper if the investor get the idea of the token he will receive so far 
    //so let create an event that will do this 
    event Invest(address _address, uint value, uint token);
    
    //create invest function in which when someone send ETH to the contract 
    //investors will call it when sending ETH to the contract
    function invest() payable public  returns(bool) {
        //first get the current state of ICO
        icoState = getCurrentState();
        //check if the ICO current state is in running state 
        require(icoState == State.RUNNING, "ICO must be in running state");
        //check if the value sent is within the require amount 
        require(msg.value >= minInvestment && msg.value <= maxInvestment, "Tha value must be within the investment range");
        //add the value sent to the raisedAmount
        raisedAmount += msg.value;
        //check if the max amount needed for the ICO has been reached 
        require(raisedAmount <= hardcap);
        //calculate the number of ELDER token that the investor will get for the ETH he just sent 
        uint token = msg.value /tokenPrice;
        
        //add it the balnce of the sender 
        balances[msg.sender] +=  token;
        //remove the same token from the founder;
        balances[founder] -= token;
        //transer the value just send to the address specify;
        deposit.transfer(msg.value);
        
        //finally emit the event 
        emit Invest(msg.sender, msg.value, token);
        
        return true;
    }
    
    //the contract can only receive money if there receive function 
    receive() payable external {
        invest();
    }
    
    
    //sometimes, the holders hurry to sell their token when the ICO end 
    //and this will collapse the price of the token 
    //therefore it will be good if you implement locking up token function
    function transfer(address to, uint token) public  override returns(bool success) {
        //first the token must been ended
        require(block.timestamp > tokenTradeStart);
        OkunCryptos.transfer(to, token);
        //you can also do this 
        //super.transfer(to, token);
        return true;
    }
    function transferFrom(address from, address to,uint tokens) public  override returns(bool success) {
         //first the token must been ended
        require(block.timestamp > tokenTradeStart);
        OkunCryptos.transferFrom(from, to,  tokens);
        //you can also do this 
        //super.transfer(to, token);
        return true;
    }
    
    //another good practice is to burn the token that has not been sold in the ICO 
    //generally burning token increases the price 
    function burn() public returns(bool) {
        //please note that enyone can call this function 
        //this is to ensure that the admin does not change his mind
        //by keeping the token 
        icoState = getCurrentState();
        require(icoState == State.AFTEREND);
        balances[founder] = 0; //this token has just been valished.
        return true;
    }
     
    
    
    
}


