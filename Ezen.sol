pragma solidity ^0.8.7;

// SPDX-License-Identifier:UNLICENSED
//v1.0

contract Ezen{

    //Owner is deployer of the contract
    address payable owner;

    constructor () {
        owner = payable(msg.sender);
        betCount=0;
    }

    //Deployer options
    modifier onlyOwner{
        require(msg.sender == owner,"Only the owner can use this function");
        _;
    }

    //Contract deletion
    function kill() external payable onlyOwner{
        selfdestruct(owner);
    }

    struct betStruct{
        address payable player;
        uint256 stake;
        uint256 payout;
        uint8 game;
        bool hasWon;
    }

    event Result(
        address account,
        uint8 result,
        bool hasWon
    );

    //Bet mapping
    mapping (uint256 => betStruct) public Bets;
    uint256 public betCount;
    uint256 public maxPayout;

    //Main funciton
    function castBet(uint8[] calldata _bet,uint8 _betlimit) external payable returns(uint8,bool){

        uint256 payout = (msg.value*_betlimit)/_bet.length - ((msg.value*_betlimit)/_bet.length)/100;

        maxPayout = address(this).balance/10;           //The bet must not payout more than 10% of the pot

        require(
            payout <= maxPayout,    //The amount staked must be within a certain range
            "Bet not within range"
        );

        //Generate a random number
        uint8 randomGen = uint8(uint256(keccak256(abi.encodePacked(block.timestamp,block.number,betCount)))%_betlimit);

        //Checking win
        bool win = false;

        //Check for etheroll
        if(_betlimit != 100){
            for (uint8 i=0;i <= _bet.length-1;i++){
                if (_bet[i]==randomGen){
                    win = true;
                    break;
                }
            }
        }else{
            if(_bet[0] >= randomGen){
                payout=(msg.value*_betlimit)/_bet[0] - ((msg.value*_betlimit)/_bet[0])/100;
                win=true;
            }
        }
 
        //Payments
        if(win == true){
            //win
            emit Result(msg.sender,randomGen,true);
            (bool success, ) = payable(msg.sender).call{value:payout}("");
            require(success, "Transfer failed.");
            Bets[betCount] = betStruct(payable(msg.sender),msg.value,payout,_betlimit,true);
        }else{
            //Lose
            emit Result(msg.sender,randomGen,false);
            Bets[betCount] = betStruct(payable(msg.sender),msg.value,payout,_betlimit,false);
        }

        //Functional data
        maxPayout = address(this).balance/10;
        betCount++;
        return (randomGen,win);
    }

    fallback() external payable {

    }
    
    receive () external payable {

    }
}