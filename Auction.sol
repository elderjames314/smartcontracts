// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
/**
 * This is Decentralize Aution smart contract as an eBay alternative
 * it will have the owner(that sell goods or services) and it will start and end date
 * Anyone with ETH wallet ID can place a bid by calling placeBid() function
 * Note the owner will not allow to bid so that he/she will not artificially increase the price
 * Anyone can bid with any amount but they are bind to previous bid (in other words your bid must be greater than previous)
 * the contact will automatically increase the bid to full amount
 * the highest binding bid is the selling price and the highest binding bidder won the Aution
 * after the aution ends the owner gets the highest binding bid and everyone else withdraw thier biding amount
 * 
*/
contract Auction {
    /*
        STATE VARIABLES
    */
   
    //the address that the highest biding bid amount will go to when the aution is complete
    //the owner of the goods or services for the aution
    address payable public owner;
    
    /*
    DISCLAMER: we cannot use block timestamp of the blockchain becuase it is being set/manipulation by 
    miners as proof of work/stake. therefore we will need to do our calculation of timestamp in the constructor.
    which will be initialized as the contract started.
    */
    //this will hold aution start time
    uint public startBlock;
    //this will hold aution end time
    uint public endBlock;
    //it is worth noting that the aution will have some information such as images, files, content of the goods or services
    //and it is costly to save those in the blockchain, therefore we will be persisting those 
    //on the IPFS(interplanetary file system), a decentralize server to hold files without cost.
    //IPFS - is a distributed system for storing and accessing files, websites, applications, and data.
    string public ipfsHash;
    //this is an enumeration that will hold the state of the aution. at any point in time aution can said to be started 
    //running, ended or cancled.
    enum  State {STARTED, RUNNING, ENDED, CANCELED }
    //declare aution state 
    State public autionState;
    //automatically this is the variable that will hold the selling price
    uint public highestBindingBid;
    //this is address that of highest bidder in which we will transfer money to the owner address.
    //will also make it payable becuase he can alos receive his funds incase the aution is canceled or outbided
    address payable public highestBidder;
    //this map(key/value pair) will hold all the bidders against their bids
    mapping(address => uint) public bids;
    //the contract will automatically bid in steps with this increment
    uint bidIncrement;
    
    
    
    //contructor will start as the contract is deployed
    //initialized state variables
    //pass external owned account to deploy the auction contract
    constructor(address eoa) {
        //set the address of the person the deploy the contract as the owner.
        owner = payable(eoa);
        //set the aution state to RUNNING
        autionState = State.RUNNING;
        //etherium block time is 15secs. so any block is added at every 15 seconds
        //the aution will start right way by setting start block to current block 
        startBlock = block.number;
        //we want our aution to be running in a week
        //for every 15sec there is one block 
        //how many ethereum block will be generated in a week
        //how many seconds in a week = 60 * 60 * 24 * 7 = 604,800sec
        //604,800/15 = 40,320 blocks 
        //endBlock = startBlock + 40320; //it means that this aution will done in 7days time.
        endBlock = startBlock + 3; //for testing purpose, end the aution after three blocks
        ipfsHash = "";
        //aution bid will start by 100 wei for instance
       // bidIncrement = 100;
        bidIncrement = 1000000000000000000; //for testing purpose, increase bid by 1 ETH;
    }
    
    //retriction to make user that caller is not the owner
    modifier notOwner() {
        require(msg.sender  != owner, "Oops!, it appears that you are the owner of this aution, thereore you can not place a bid");
        _;
    }
    //ensure the aution start is greater or equal to startBlock;
    modifier afterStart() {
        require(block.number >= startBlock, "aution period must between the aution start and end time");
        _;
    }
    //ensure the aution time before or equal to endblock time;
    modifier beforeEnd() {
        require(block.number <= endBlock, "aution period must between the aution start and end time");
        _;
    }
    //you must be the owner before you can be called
    modifier onlyOwner() {
        require(msg.sender == owner, "Oops! it appears you are not the owner of this contract");
        _;
    }
    
     //it is declare pure because is neither write or read from blockchain
    function min(uint a, uint b) pure private returns(uint) {
        if(a <= b) return a;
        return b;
    }
    
    //incase of anything and the owner wishes to cancel the option 
    function cancelAution() public onlyOwner {
        //first change the auction state to cancel, so that someone cannot place a bid 
        autionState = State.CANCELED;
        
    }
    
    //place bids and it will payable because it will receive ether 
    //apply the neccessary constrait to paybid
    function placeBid() public payable notOwner afterStart beforeEnd {
        
        //for someone to be able to place a bid, the aution must be in a running state 
        require(autionState == State.RUNNING);
        //also the bid amount must be greater than or equal 100 wei
        require(msg.value >= 100, "Bid amount must be equal to or greater than 100 wei");
        
        //incase of the current sender has already bid before... sum of the previous bid to current bid now
        //and if this is the first time, no cause for alarm, the previous bid will be zero
        uint currentBids = bids[msg.sender] + msg.value;
        
        //any point in time current bid should be greater than highest binding value;
        //if is less, then don't do continue..just stop
        require(currentBids > highestBindingBid);
        
        //if you got here, then update the current bid value to current sender
        bids[msg.sender] = currentBids;
        
        //incase the currentBids is less than equal highest bidder 
        if(currentBids <= bids[highestBidder]) {
            highestBindingBid = min(currentBids + bidIncrement, bids[highestBidder]);
        }else {
            highestBindingBid = min(currentBids, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
        
    }
    
    //now bring the aution to end.
    function finalizingAution() public {
        //fist, aution must either be cancled or expired.
        require(autionState == State.CANCELED || block.number > endBlock, "Before you can finalize the aution, it must be on canceled state or end time end");
        //it is the owner or anyone of the bidder can finalize the aution
        require(msg.sender == owner || bids[msg.sender] > 0 , "Auction can only be finalized by the owner or any of the bidder");
        
        address payable recipient;
        uint value;
        
        if(autionState == State.CANCELED) {
            //it means aution was canceled 
            //therefore everybody will make withrawal request to get thier money including the highest bidder;
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else {
            //aution ended successfully (not CANCELED)
            if(msg.sender == owner) {
                //this is the case when the owner comes to receive his money 
                recipient = owner;
                value = highestBindingBid;
            }else {
                //here, one of the bidder came to request hist/her funds.
                //bidder;
                //if this is the highest bidder, he/she will receive the difference, that is seling price - highest bidding amount
                if(msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid; //total amount bids - the selling price
                }else {
                    //normal bidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
           
            }
        }
        
        //after all said and done. all requirement fulfiled, then gracefully make the transfer 
        recipient.transfer(value);
        
        //once the recipient gets its money,
        //reset its bid so that he/she will not be consider bidder anymore 
        bids[recipient] = 0;
        
    }

}


contract AutionManager {
    //this is the address that will deploy aution contract
    //and it will be response for gas payment
    address public ownerCreator;
    //the dynamic array will keep track of instance of auction (deployed);
    Auction[] public deployedAuctions;
    
    constructor() {
        ownerCreator = msg.sender;
    }
    
    function deployAuction() public {
        Auction auction = new Auction(msg.sender);
        //add deployed auction to array of deployed auctions
        deployedAuctions.push(auction);
    }
}