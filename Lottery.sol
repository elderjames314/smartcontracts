// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    
    //this will hold the players, since we do not know how many players that
    //will play the lottery, it is declare as dynamic array
    address payable[] public playerAddresses;
    
    //the address of the manager that will deploy and control the contract
    address immutable public manager;
    
    //initializing the manager as the owner of the contract
    //once the contract is depoyed.
    constructor() {
        manager = msg.sender;
        //here immediately the contract is deploy, manager will be automatically added to the contest without sending an ether
        playerAddresses.push(payable(msg.sender));
    }
    
    //this indicate that the contract can receive ether
    receive() external payable {
        //check that the manager cannot perform the lottery contest
        require(manager != msg.sender, "Oops!, it appears that you are a manager, therefore you cannot perform in the lottery contest");
        //we require user to send fix amount(0.1 ETH) to the lottery contract
        //however user cannot send as much as fix amount as possible.
        require(msg.value == 0.1 ether, "You are required to send 0.1 ETH at a time to the lottery contract");
        //for every payment made for the lottery, add the sender to the array
        //we are not interested how much the sender have sent
        //once this function is automatically called, we want to believe they have been payment made
        //therefore add the sender to the dynamic array
        playerAddresses.push(payable(msg.sender));
    }
    function getBalance() public view returns(uint) {
        //only the manager can see the balance
        require(msg.sender == manager, "It appears that you are not the manger of this contract!");
        return address(this).balance;
    }
    //in other to generate the winner, we need to generate high computation numbers by using
    //block difficulty, block timestamp and total numbers of players
    //the we will modulus the high numbers but players array length
    //the result index is the winner.
    function generateRandomNumber() view public returns(uint)  {
        //pls this is not recommended way of generating random. solidty community advise we use chainingURF API
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, playerAddresses.length)));
    }
    
    //pick the winner
    function pickWinner()  public{
        //it is only the manager that can pick the winner  if the players is less than 10 otherwise anyone can pick a winner
        require(manager == msg.sender, "Oops! only the manager is allowed to pick the winner");
        //before you can select winner, players must at least be three 
        require(playerAddresses.length >= 3, "Oops, Before you can pick a winner, total numbers of players must at least be three");
        //get the index of the winner based on the generated random numbers
        uint index = generateRandomNumber() % playerAddresses.length;
        //get the total balance of the contract
        uint totalMoneyInTheContract = getBalance();
        //calculate the ten percent of the contract balance
        uint tenPercentForTheManager =  uint(10)/uint(100) * totalMoneyInTheContract;
        //find the remaining amount that will be sent to the winner
        uint remainAmountToTheWinner = totalMoneyInTheContract - tenPercentForTheManager;
        //send the ten percent to the manager
        payable(manager).transfer(tenPercentForTheManager);
        //send the remaining amount to the winner
        playerAddresses[index].transfer(remainAmountToTheWinner);
        //reset the lottery
        reset();
        
    }
    
    function reset() private {
        //then reset the lottery so that it will be ready for next round
        playerAddresses = new address payable[](0); 
        //add the manager
        playerAddresses.push(payable(manager));
    }
}