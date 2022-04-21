//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract Crowdfunding{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmt;
    uint public noOfContribs;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint numRequests;

    constructor(uint _target, uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline; //
        minContribution=100 wei;
        manager=msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp<deadline,"Deadline passed");
        require(msg.value>=minContribution,"Minimum Contribution is not met");

        if(contributors[msg.sender]==0){
            noOfContribs++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmt+=msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp>deadline && raisedAmt<target,"You are not eligible for the refund");
        require(contributors[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    modifier onlyManager(){
        require(msg.sender==manager,"Only manager allowed to call the function");
        _;
    }

    function createRequest(string memory _desc,address payable _recipient, uint value) public onlyManager{
        Request storage newRequest=requests[numRequests];
        numRequests++;
        newRequest.description=_desc;
        newRequest.recipient=_recipient;
        newRequest.value=value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be a contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function payment(uint _requestNo) public onlyManager{
        require(raisedAmt>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"Request has been already completed");
        require(thisRequest.noOfVoters>noOfContribs/2);
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}