// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

/**
 * A CrowdFunding DeFi that will solve the problem of admin runnig away with money without doing actual project.
 * Admin will start the campaign with monetary goal and deadlines.
 * Contributor will contribute to the project by sending ETH 
 * Admin will create spending request for the campaign
 * The contributor will start voting for the spending request
 * If more than 50% vote for that spending request, then admin will be permited to spend the money
 * in the spen request else all the contribute will withdraw their money
 * IN ESSENCE, THE POWER OF THE CAMPAIGN IS MOVED FROM ADMIN TO DONATED CONTRIBUTORS.
 * the contributor can request refund of the monetary goal did not meet the deadlines.
 */ 
contract CrowdFunding {
    
    //the contributors of the campaign with their address and the amount donated.
    mapping(address => uint) public contributors;
    //the manager or administrator of the campaign
    address public admin;
    //We need to know the number of the contributors to the campaign 
    uint public numberOfContributors;
    //declare variable to hold minimum contribution
    uint public minimumContribution;
    uint public deadline; //this is timestamp, in seconds pls;
    uint public goal; //the goal amount;
    uint public raisedAmount; //the amount of money raised.
    
    //anytome Admin wants to spend money, he/she must create spending request
    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool isCompleted;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }
    
    mapping(uint => Request) public requests;
    uint public numberOfRequest;
    
    //event that will emitted and called by external factor such as JS. 
    event ContributeEvent(address _address, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    //initialize 
    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline; // 86,400
        minimumContribution = 100 wei;
        admin = msg.sender;
    }
    
    //only admin can perform this
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    //is time to make payment to the recipient of the spending request 
    //before admin can make payment, the request must have been created,
    //50% of contrubutors must have been voted yes for that spending rrequest
    function makePayment(uint _requestNumber) public onlyAdmin {
        //first check of the goal was meant
        require(raisedAmount >= goal, "The goal must be meant before you can make payment");
        //lookup for the request to make payment for
        Request storage thisRequest = requests[_requestNumber];
        //to avoid double spending, check if the request has been completed.
        require(thisRequest.isCompleted == false, "Oops!, this request has already be completed");
        //check if the number of voters is greater than 50%
        require(thisRequest.numberOfVoters > numberOfContributors / 2, "Oops!, more than 50% must vote before the payment can go through"); //if true, it means 50% has already been voted
        //finally make the transfer
        thisRequest.recipient.transfer(thisRequest.value);
        //mark this request as completed
        thisRequest.isCompleted = true;
        
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
    //the function that contributors will call to vote rRequest
    function voteRequest(uint _requestNumber) public {
        //before you cn vote, you must be a contributors.
        require(contributors[msg.sender] > 0, "You must be a contributors to vote");
        //get the request you wnat to vote for 
        Request storage thisRequest = requests[_requestNumber];
        //the contributor are allowed to vote only once.
        //thefore we need to check if this ccontributor has voted before
        require(thisRequest.voters[msg.sender] == false, 'You have already voted for this request');
        thisRequest.voters[msg.sender] = true;
        thisRequest.numberOfVoters++;
    }
    
    //create spending rrequests
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numberOfRequest++];
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.isCompleted = false;
        newRequest.numberOfVoters = 0;
        
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    //send money to the contract 
    function contribute() public payable {
        //first check if the campaign is still running 
        require(block.timestamp < deadline, "Campaign has passed, therefore you can no longer send money to this campaign");
        //the value of wie sent must greater or equal to minimum contribution
        require(msg.value >= minimumContribution, "Sorry amount must greater than or equal to 100 wei");
        if(contributors[msg.sender] == 0) {
            //this is the first time
            //therefore increase the number of contributor 
            numberOfContributors++;
        }
        //add the amount sent
        contributors[msg.sender] += msg.value;
        //increase raise amount by the money sent 
        raisedAmount += msg.value;
        
        //emit the event 
        emit ContributeEvent(msg.sender, msg.value);
    }
    
    //so that the contract
    receive() payable external {
        contribute();
    }
    //get the balance of the contract 
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    //make a refund
    function refund() public {
        //first check that the dealine has passed and the set goal was not meant.
        require(block.timestamp > deadline && raisedAmount < goal, "the campaign must have passed and raised amount is less than goal");
        //Only the contributor can make refund and he/she should have sent money
        require(contributors[msg.sender] > 0, "only contributor can make refund");
        
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        
        //make the transfer
        recipient.transfer(value);
        
        //finally set his contribution to zero
        contributors[msg.sender] = 0;
    }
    
}