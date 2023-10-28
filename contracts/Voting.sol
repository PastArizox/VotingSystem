// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    } // Une personne qui vote

    struct Proposal {
        string description;
        uint voteCount;
    } // Une proposition de vote

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    } // Différents états d'un vote

    event VoterRegistered(address voterAddress);
    event VoterRemoved(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    uint winningProposalId;
    mapping(address => Voter) voters;
    Proposal[] proposals;
    WorkflowStatus workflowstatus;

    address owner;

    constructor() {
        owner = msg.sender;
        workflowstatus = WorkflowStatus.RegisteringVoters;
    }

    // Modifiers

    modifier isOwner() {
        require(msg.sender == owner, "You don't have the permission to do that");
        _;
    }

    modifier isRegistered() {
        require(voters[msg.sender].isRegistered, "You are not a registered voter");
        _;
    }

    modifier isStatus(WorkflowStatus status, string memory errorMessage) {
        require(workflowstatus == status, errorMessage);
        _;
    }

    // Owner actions

    function registerVoter(address _addressOfVoter) public isOwner {
        require(!voters[_addressOfVoter].isRegistered, "User already registered");
        voters[_addressOfVoter].isRegistered = true;
        emit VoterRegistered(_addressOfVoter);
    }

    function unregisterVoter(address _voterAddress) external isOwner {
        require(voters[_voterAddress].isRegistered, "This voter is not registered");
        delete voters[_voterAddress];
        emit VoterRemoved(_voterAddress);
    }

    function startProposalRegisterSession() public isOwner {
        emit WorkflowStatusChange(workflowstatus, WorkflowStatus.ProposalsRegistrationStarted);

        workflowstatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function endProposalRegisterSession() public isOwner isStatus(WorkflowStatus.ProposalsRegistrationStarted, "Proposal register session is not open") {
        workflowstatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVoteSession() public isOwner isStatus(WorkflowStatus.ProposalsRegistrationEnded, "Proposal register session is not closed") {
        workflowstatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVoteSession() public isOwner isStatus(WorkflowStatus.VotingSessionStarted, "Vote session is not open") {
        workflowstatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    function tallyVotes() external isOwner isStatus(WorkflowStatus.VotingSessionEnded, "Vote session is not closed") {
        uint winningCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningCount) {
                winningCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        
        workflowstatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    // Voters actions

    function registerProposal(string memory _description) public isRegistered isStatus(WorkflowStatus.ProposalsRegistrationStarted, "Proposal register session is not open") {
        uint proposalId = proposals.length;
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposalId);
    }

    function vote(uint _proposalId) public isRegistered isStatus(WorkflowStatus.VotingSessionStarted, "Voting session is not open") {
        require(!voters[msg.sender].hasVoted, "You already voted");
        require(_proposalId < proposals.length, "This proposal doesn't exist");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        emit Voted(msg.sender, _proposalId);
    }

    // All access

    function getWinner() external view isStatus(WorkflowStatus.VotesTallied, "Votes didn't get counted") returns (uint) {
        return winningProposalId;
    }

    function viewProposal(uint _proposalId) external view returns (string memory) {
        require(_proposalId < proposals.length, "The proposal doesn't exist");
        return proposals[_proposalId].description;
    }

    function viewProposals() external view returns (Proposal[] memory) {
        require(proposals.length > 0, "There is no proposal");
        return proposals;
    }
}