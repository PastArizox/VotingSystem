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
    event Voted (address voter, uint proposalId);

    uint winningProposalId;
    mapping(address => Voter) voters;
    Proposal[] proposals;
    WorkflowStatus workflowstatus;

    address owner;

    constructor() {
        owner = msg.sender;
        workflowstatus = WorkflowStatus.RegisteringVoters;
    }

    function getWinner() public view returns (uint) {
        return winningProposalId;
    }
}