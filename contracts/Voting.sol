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

    function registerVoter(address _addressOfVoter) public {
        require(msg.sender == owner, "You don't have the permission to do that");
        require(!voters[_addressOfVoter].isRegistered, "User already registered");
        voters[_addressOfVoter].isRegistered = true;
        emit VoterRegistered(_addressOfVoter);
    }

    // Start/Stop sessions (owner only)

    function startProposalRegisterSession() public {
        require(msg.sender == owner, "You don't have the permission to do that");
        emit WorkflowStatusChange(workflowstatus, WorkflowStatus.ProposalsRegistrationStarted);

        workflowstatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function endProposalRegisterSession() public {
        require(msg.sender == owner, "You don't have the permission to do that");
        require(workflowstatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposal register session is not open");

        workflowstatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVoteSession() public {
        require(msg.sender == owner, "You don't have the permission to do that");
        require(workflowstatus == WorkflowStatus.ProposalsRegistrationEnded, "Proposal register session is not closed");

        workflowstatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVoteSession() public {
        require(msg.sender == owner, "You don't have the permission to do that");
        require(workflowstatus == WorkflowStatus.VotingSessionStarted, "Vote session is not opened");

        workflowstatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    // Proposal/Voting (registered users)

    function registerProposal(string memory _description) public {
        require(voters[msg.sender].isRegistered, "You are not a registered user");
        require(workflowstatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposal register session is not open");

        uint proposalId = proposals.length;
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposalId);
    }

    function vote(uint _proposalId) public {
        require(voters[msg.sender].isRegistered, "You are not a registered user");
        require(workflowstatus == WorkflowStatus.VotingSessionStarted, "Voting session is not open");
        require(!voters[msg.sender].hasVoted, "You already voted");
        require(_proposalId < proposals.length, "This proposal doesn't exists");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        emit Voted(msg.sender, _proposalId);
    }

    // Count votes

    function tallyVotes() external {
        require(msg.sender == owner, "You don't have the permission to do that");
        require(workflowstatus == WorkflowStatus.VotingSessionEnded, "Vote session is not closed");

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

    function getWinner() external view returns (uint) {
        require(workflowstatus == WorkflowStatus.VotesTallied, "Votes didn't get counted");
        return winningProposalId;
    }
}