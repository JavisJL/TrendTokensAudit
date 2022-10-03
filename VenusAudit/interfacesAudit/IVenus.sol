// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

interface IVenus {
    function enterMarkets(address[] calldata _markets) external returns(uint[] memory);
    function claimVenus(address holder, address[] memory vTokens) external;
    function claimVenus(address _recipient) external;
    function venusAccrued(address holder) external view returns(uint256);

    function getAssetsIn(address account) external view returns (address[] memory);
    function markets(address vTokenAddress) external view returns (bool, uint, bool); // (isListed, collateralFactorMantissa, isXvsed)
    function getAccountLiquidity(address account) external view returns (uint, uint, uint); //  (error, liquidity, shortfall)

    function closeFactorMantissa() external view returns (uint); // multiply by token borrow balance to see how much can be repaid
    function exitMarket(address vToken) external returns (uint);

    function getHypotheticalAccountLiquidity(address account,address vTokenModify,uint redeemTokens,uint borrowAmount) external view returns (uint, uint, uint);
    
}
