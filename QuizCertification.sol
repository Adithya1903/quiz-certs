// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QuizCertification is ERC721Enumerable, Ownable {
    uint256 public nextCertId = 1;
    uint256 public nextQuestionId = 1;

    struct Certificate {
        string courseName;
        uint256 issuedAt;
        uint256 score;
    }

    struct Question {
        bytes32 answerHash;
        string courseName;
        uint256 score;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(uint256 => Question) public questions;
    mapping(address => uint256) public reputation;
    mapping(address => mapping(uint256 => bool)) public completed;

    constructor() ERC721("Quiz Certification", "QCERT") Ownable(msg.sender) {}

    function addQuestion(
        string memory courseName,
        string memory correctAnswer,
        uint256 score
    ) external onlyOwner {
        require(score > 0, "Score must be > 0");

        uint256 qid = nextQuestionId++;
        questions[qid] = Question({
            answerHash: keccak256(abi.encodePacked(correctAnswer)),
            courseName: courseName,
            score: score
        });
    }

    function submitAnswer(uint256 qid, string memory answer) external {
        require(!completed[msg.sender][qid], "Already completed");
        require(qid > 0 && qid < nextQuestionId, "Invalid question");

        Question memory q = questions[qid];
        require(keccak256(abi.encodePacked(answer)) == q.answerHash, "Incorrect answer");

        completed[msg.sender][qid] = true;

        uint256 certId = nextCertId++;
        _safeMint(msg.sender, certId);

        certificates[certId] = Certificate({
            courseName: q.courseName,
            issuedAt: block.timestamp,
            score: q.score
        });

        reputation[msg.sender] += q.score;
    }

    function getCertificate(uint256 certId)
        external
        view
        returns (string memory courseName, uint256 issuedAt, uint256 score)
    {
        Certificate memory cert = certificates[certId];
        return (cert.courseName, cert.issuedAt, cert.score);
    }

    function getReputation(address student) external view returns (uint256) {
        return reputation[student];
    }

    // Prevents transfers; only mint (from 0) and burn (to 0) are allowed
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: transfer disabled");
        }
        return super._update(to, tokenId, auth);
    }
}

//