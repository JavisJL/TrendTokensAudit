// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

// maybe use IVBep20 for BNB except for mint() and repayBorrow()

interface IVBNB {
    function balanceOf(address _owner) external view returns(uint256);
    function balanceOfUnderlying(address _owner) external returns(uint256);

    function mint() external payable; // different for IVBep20
    function repayBorrow() external payable;

    function redeemUnderlying(uint256 _amount) external returns(uint256);
    function exchangeRateStored() external view returns(uint256);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrow(uint256 _amount) external returns(uint256);


    //function borrowRatePerBlock() external returns (uint);
    //function supplyRatePerBlock() external returns (uint);

    // view functions
    //function balanceOf(address owner) external view returns (uint);
    //function allowance(address owner, address spender) external view returns (uint);

    // return (possible error, token balance, borrow balance, exchange rate mantissa)
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    //function borrowRatePerBlock() external view returns (uint);
    //function supplyRatePerBlock() external view returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    //function exchangeRateStored() public view returns (uint);
    //function getCash() external view returns (uint);

    // not view functions
    //function transfer(address dst, uint amount) external returns (bool);
    //function transferFrom(address src, address dst, uint amount) external returns (bool);
    //function approve(address spender, uint amount) external returns (bool);
    //function balanceOfUnderlying(address owner) external returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    //function borrowBalanceCurrent(address account) external returns (uint);
    //function exchangeRateCurrent() public returns (uint);
    //function accrueInterest() public returns (uint);
    //function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

}


