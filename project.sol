// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedLending {
    address public owner;

    struct Loan {
        address borrower;
        uint amount;
        uint repaymentAmount;
        uint dueDate;
        bool repaid;
    }

    mapping(uint => Loan) public loans;
    mapping(address => uint[]) public borrowerLoans;

    uint public loanCount;
    uint public interestRate; // Interest rate in percentage

    event LoanRequested(uint loanId, address borrower, uint amount, uint repaymentAmount, uint dueDate);
    event LoanRepaid(uint loanId, address borrower, uint repaymentAmount);
    event LoanDefaulted(uint loanId, address borrower, uint repaymentAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyBorrower(uint loanId) {
        require(loans[loanId].borrower == msg.sender, "Only borrower can perform this action");
        _;
    }

    constructor(uint _interestRate) {
        owner = msg.sender;
        interestRate = _interestRate; // Example: Pass 5 for 5% interest
    }

    function requestLoan(uint _amount, uint _duration) external {
        require(_amount > 0, "Loan amount must be greater than 0");
        require(_duration > 0, "Loan duration must be greater than 0");

        uint repaymentAmount = _amount + ((_amount * interestRate) / 100);
        uint dueDate = block.timestamp + _duration;

        loans[loanCount] = Loan({
            borrower: msg.sender,
            amount: _amount,
            repaymentAmount: repaymentAmount,
            dueDate: dueDate,
            repaid: false
        });

        borrowerLoans[msg.sender].push(loanCount);

        emit LoanRequested(loanCount, msg.sender, _amount, repaymentAmount, dueDate);

        loanCount++;
    }

    function fundLoan(uint loanId) external payable onlyOwner {
        Loan storage loan = loans[loanId];
        require(loan.amount == msg.value, "Incorrect funding amount");
        require(!loan.repaid, "Loan already repaid");

        payable(loan.borrower).transfer(loan.amount);
    }

    function repayLoan(uint loanId) external payable onlyBorrower(loanId) {
        Loan storage loan = loans[loanId];
        require(!loan.repaid, "Loan already repaid");
        require(msg.value == loan.repaymentAmount, "Incorrect repayment amount");

        loan.repaid = true;
        payable(owner).transfer(msg.value);

        emit LoanRepaid(loanId, msg.sender, msg.value);
    }

    function markDefaulted(uint loanId) external onlyOwner {
        Loan storage loan = loans[loanId];
        require(block.timestamp > loan.dueDate, "Loan is not overdue yet");
        require(!loan.repaid, "Loan already repaid");

        emit LoanDefaulted(loanId, loan.borrower, loan.repaymentAmount);
    }

    function getBorrowerLoans(address _borrower) external view returns (uint[] memory) {
        return borrowerLoans[_borrower];
    }

    function updateInterestRate(uint _newRate) external onlyOwner {
        interestRate = _newRate;
    }
}

