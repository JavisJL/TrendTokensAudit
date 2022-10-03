// SPDX-License-Identifier: ISC
pragma solidity ^0.8.14;

import "./VenusBase.sol";

// add maxExposure to main contract

/**
*   This contract includes all the Venus business logic in the main contract
*   except deposit and redeem use 
*
*   This contract allows the manager to borrow, repay, redeem, supply, and 
*/
contract VenusBusinessLogic is Venus {
    /**
    *   This contract allows for the manager to supply, redeem, borrow, repay within safety limitations
    *   The Manager is restricted by safety parameters to avoid negatively affecting the pool of assets in this contract
    *   Some limitations are: 
    *       -* cannot supply or borrow tokens that are not enabled (result in lost funds if supply to disabled market!)
    *       - borrow and redeem to not exceed dropTolerance (min percent market drop before contract gets liquidated --> must be above this level)
    *       - all borrow, redeem, repay, supply actions must be within minVenusVal and maxVenusVal values (too small --> waste of gas and Venus errors)
    *       - cannot hold supply or borrow positions that exceeds maxExposure (for example, supply+borrow cannot exceed 10% of availabe cash in market)
    *       - cannot enable markets (allows to supply and borrow) that are not in the list of hardcoded inVenus token list (cant just enable any token)
    *       - cannot enable markets with collateralFactors < minColFactor (too high risk assets)
    *       - cannot disable markets that current hold balances above minTradeVal (would mess up TrendToken price calculation as it would ignore equity)
    *       - cannot redeem collateral earnings (in XVS) if its below the minVenusVal as it is a waste of gas
    *   The Owner has the ability to change many of these safety paramter values, but there are hardcoded limits on each
    */

    // Update Fees
    uint public colManagerShare = 0.25e18; // Percentage of collateral interest that goes to feeRecipient

    // Update Deposits 
    uint public dropTolerance = 0.10e18; // percentage assets allowed to drop before liquidation (safety)

    // Admin Addresses
    address public owner; // ability to borrow, repay, supply, redeem
    address public manager; // ability to borrow, repay, supply, redeem
    address public feeRecipient; // address of recipient of collateral share

    // Token Addresses
    IERC20 public immutable wbnb;
    IERC20 public immutable busd;
    IERC20 public immutable xvs;


    // update Venus
    bool public enabledVenus = true;
    uint public minVenusVal = 1e9;
    uint public maxVenusVal = 10000e18;
    uint public minColFactor = 0.5e18; 
    uint public maxExposure = 0.10e18;

    // Update Pancake
    uint public minTradeVal = 1e12;


    // Modifier 
    function onlyModifiers(address _owner, string memory message) view internal {
        require(msg.sender == _owner, message);
    }

    modifier onlyOwner() {
        onlyModifiers(owner,"!owner");
        _;
    } 

    modifier onlyManager() {
        onlyModifiers(manager,"!manager");
        _;
    } 


    // mainnet: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63,0xfD36E2c2a6789Db23113685031d7F16329158384,0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F,true
    // testnet: 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47,0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd,0xB9e0E753630434d7863528cc73CB7AC638a7c8ff,0x94d1820b2d1c7c7452a163983dc888cec546b77d,0x03cf8ff6262363010984b192dc654bd4825caffc,false
    constructor(address _busd, address _wbnb, address _xvs, address _venus, address _venusOracle, bool _isMainnet) 
    Venus(_busd, _wbnb,_xvs,_venus,_venusOracle, _isMainnet)  {
        owner = msg.sender;
        manager = msg.sender;
        feeRecipient = msg.sender;
        wbnb = IERC20(_wbnb);
        busd = IERC20(_busd);
        xvs = IERC20(_xvs);
        IERC20[] memory startPort = new IERC20[](3);
        startPort[0] = busd; startPort[1] = wbnb; startPort[2] = xvs;
        enableCol(startPort); // run function upon deployement
    }

    // -------- RECEIVE AND VIEW CONTRACT BALANCES ------------ //

    receive() external payable {}

    /**
    *   Used to fetch contract balances of bep20 tokens
    */
    function contractBal(IERC20 _token) public view returns(uint) {
        if (_token == wbnb) { return address(this).balance;
        } else { return _token.balanceOf(address(this));}
    }


    // ------------- ADMIN ADJUSTABLE FEATURES -------------- // 

    function updateVenus(uint _minVenusVal, uint _maxVenusVal, uint _minColFactor, uint _maxExposure, bool _enabledVenus) onlyOwner external {
        require(_minVenusVal >= 1e12 && _maxVenusVal <= 100000000e18 && _minColFactor>=0.4e18 && _maxExposure <= 0.50e18,"invalid Venus inputs");
        minVenusVal = _minVenusVal; // min amount to borrow,repay,redeem,supply
        maxVenusVal = _maxVenusVal;
        minColFactor = _minColFactor; // min collateral factor to enable token
        maxExposure = _maxExposure;
        enabledVenus = _enabledVenus;
    }





    function updateVenus(uint _colManagerShare, uint _dropTolerance, uint _minTradeVal) onlyOwner external {
        require(_colManagerShare >= 0.75e18 && _dropTolerance >= 0.10e18 && _minTradeVal>=1e18,"invalid inputs");
        colManagerShare = _colManagerShare; // min amount to borrow,repay,redeem,supply
        dropTolerance = _dropTolerance;
        minTradeVal = _minTradeVal;
    }






    // -------- ENABLE AND DISABLE TOKENS --------- //

    /**
    *   Allows manager to redeem collateral earnings externally
    */
    function distXVSfromInterest() onlyManager external {
        disXVSfromInter();
    }


    /**
    *   Disables token market (cant borrow or collateral)
    *   Requires token is currently enabled
    *   Requires total value (contract, collateral, borrow) is below minTradeVal
    *       otherwise Equity will drop and therefore price of Trend Token
    */
    function disableToken(IERC20 _bep20) onlyManager external {
        require(_bep20 != wbnb && _bep20 != busd && _bep20 != xvs,"cannot disable tokens");
        uint totalAmt = contractBal(_bep20) + colAmtBEP20(_bep20) + borAmtBEP20(_bep20);
        uint totalValue = Lib.getValue(totalAmt, priceBEP20(_bep20));
        require(tokenEntered(_bep20) && totalValue < minTradeVal && totalValue < 100e18,"non-zero balance.");
        disXVSfromInter();
        disableCol(_bep20);
    }


    function tokenInPortfolio(IERC20 _bep20, IERC20[] memory _portfolio) internal pure returns(bool) { // finds index of input token
        for (uint i = 0; i < _portfolio.length; i++) {
            if (_portfolio[i] == _bep20) {return true;}
        } return false; // watch out when this is used
    }


    /**
    *   Enables tokens market (borrow or collateral)
    *   Requires tokens is listed in venusTokens 
    *   requires slippage on pancake is below threshold (commented out for isolated test)
    */
    function enableTokens(IERC20[] memory _tokens) onlyManager external {
        for (uint i=0; i<_tokens.length; i++) {
            IERC20 token = _tokens[i];
            bool inVenus = tokenInPortfolio(token,venusTokens);
            require(inVenus && collateralFactor(token)>minColFactor,"cant enable");
            //pancakeCost(token, 10000e18); // checks trade fee tolerance
        }
        enableCol(_tokens);
    }


    // ------------ SUMMARIZE CONTRACT FUNCTIONS --------------- //


    /**
    *   Returns the stored contract, collateral, and borrow balances of each enabled market
    *   returns the equity (contract + collateral - borrow) of all enabled markets
    */
    function storedEquity() public view returns(IERC20[] memory,uint[] memory,uint[] memory,uint[] memory,uint[] memory,uint) {  // returns current balances (uint)
        //int[] memory prices = pricesUpdateX();

        IERC20[] memory activePort = getMarketsBEP20();
        //address[] memory activePort = getMarkets();
        uint activePortLen = activePort.length;
        uint[] memory conVals = new uint[](activePortLen);
        uint[] memory colVals = new uint[](activePortLen);
        uint[] memory borVals = new uint[](activePortLen);
        //uint[] memory netVals = new uint[](activePortLen);
        uint[] memory prices = new uint[](activePortLen);
        uint assetValSum = 0; uint borrowValSum = 0;

        for (uint i = 0; i < activePortLen; i++) {

            // fetch token and price
            IERC20 token = IERC20(activePort[i]);
            uint tokenToUSD = priceBEP20(token);
            prices[i] = tokenToUSD;
            (uint vTokenBal, uint borrowBal, uint rate) = screenshot(token);

            // contract balances
            uint _contractBal = contractBal(token);
            uint contractVal = Lib.getValue(_contractBal,tokenToUSD);
            conVals[i] = contractVal;

            // collateral values
            uint collateralAmt = Lib.getValue(vTokenBal,rate);
            uint collateralVal = Lib.getValue(collateralAmt,tokenToUSD);
            colVals[i] = collateralVal;

            // borrow values
            uint borrowVal = Lib.getValue(borrowBal,tokenToUSD);
            borVals[i] = borrowVal;
            
            assetValSum += contractVal + collateralVal;
            borrowValSum += borrowVal; 
        }

        uint netEquity = assetValSum - borrowValSum;

        //return (netEquity,conVals,colVals,borVals,activePort);
        return (activePort,prices,conVals,colVals,borVals,netEquity);
    }



    // -------------- SAFETY PARAMETERS -------------- //


    /**
    *   Requires redeem or borrow does not exceed surpass drop tolerance
    *   Calculates dropToLiquid --> percentage drop of portfolio assets before liquidation
    *       - future account liquidity (after redeem/borrow) divided by total allowed to borrow
    *           - example: 
    *   Ensures the desired redeemBEP20, redeem, or borrow does not exceed drop tolerance
    *   Drop tolerance is admin set % the account can drop before liquidation (example 20%)
    */
    function checkSafeLiquidLevels(IERC20 _modifyBep20, uint _redeemAmt, uint _borrowAmt) internal view {
        uint futureAcctLiquidity = hypotheticalAccountLiquidity(_modifyBep20, _redeemAmt, _borrowAmt);
        (,,,,uint[] memory borVals,) = storedEquity();
        
        uint futureBorrows = Lib.countValueArray(borVals) + Lib.getValue(_borrowAmt,priceBEP20(_modifyBep20));
        uint futureAllowBorrow = futureBorrows + futureAcctLiquidity;
        uint dropToLiquid = 1e18; // by default, requires 100% drop to liquidate
        if (futureAllowBorrow > 0) { 
            dropToLiquid = Lib.getAssetAmt(futureAcctLiquidity,futureAllowBorrow);
        }
        require(dropToLiquid > dropTolerance, "Would exceed liquidity.");
    }

    /**
    *   Checks if token is an active token (in Venus markets)
    *   Requirement fails if token is not active 
    */
    function checkActiveTokenX(IERC20 _bep20) internal view {
        bool tokenInPort = tokenEntered(_bep20);
        require(tokenInPort,"Token not enabled");
    }

    /**
    *   Safety parameters for all Venus functions ensure the _bep20 market is entered 
    *   and value is within [minVenusVal, maxVenusVal]
    */
    function venusRequirements(IERC20 _bep20, uint _value) internal view {
        require(tokenEntered(_bep20) && _value >= minVenusVal && _value <= maxVenusVal && enabledVenus," Venus Req.");
    }

    function sufficientMarket(IERC20 _bep20, uint _borrowVal) internal view {
        (, uint borrowBal, ) = screenshot(_bep20);
        uint exposureValue = Lib.getValue(borrowBal,priceBEP20(_bep20))+_borrowVal;
        uint marketValue = Lib.getValue(getCash(_bep20),priceBEP20(_bep20));
        uint allowedExposure = Lib.getValue(marketValue,maxExposure);
        require(exposureValue < allowedExposure, "Venus exposure exceeded.");
    }


    // ----------- REPAY, SUPPLY, BORROW, REDEEM, REDEEMEARNINGS --------- //


    /**
    *   Repays loans to Venus
    *   Ensures Venus requirements are met
    */
    function repay(IERC20 _bep20, uint _repayValue) onlyManager external {
        venusRequirements(_bep20,_repayValue);
        uint repayAmt = Lib.getAssetAmt(_repayValue,priceBEP20(_bep20));
        borRepayBEP20(_bep20, repayAmt);
    }


    /**
    *   Supplies collateral to Venus
    *   Ensures Venus requirements are met
    */
    function supply(IERC20 _bep20, uint _supplyValue) onlyManager external {
        venusRequirements(_bep20,_supplyValue);
        uint supplyAmt = Lib.getAssetAmt(_supplyValue, priceBEP20(_bep20));
        colSupplyBEP20(_bep20, supplyAmt);
    }


    /**
    *   Borrows assets from Venus
    *   Ensures Venus requirements are met
    *   Ensures borrow does not exceed safety level
    */
    function borrow(IERC20 _bep20, uint _borrowValue) onlyManager external {
        venusRequirements(_bep20,_borrowValue);
        sufficientMarket(_bep20,_borrowValue);
        uint borrowAmt = Lib.getAssetAmt(_borrowValue,priceBEP20(_bep20));
        checkSafeLiquidLevels(_bep20,0,borrowAmt);
        borBEP20(_bep20,borrowAmt);
    }


    /**
    *   Redeem collateral from Venus (ex, swap vBNB for BNB)
    *   Ensures Venus requirements are met
    *   Ensures redeem does not exceed safety levels
    */
    function redeem(IERC20 _bep20, uint _redeemValue) onlyManager external  {
        venusRequirements(_bep20,_redeemValue);
        uint redeemAmt = Lib.getAssetAmt(_redeemValue,priceBEP20(_bep20));
        checkSafeLiquidLevels(_bep20,redeemAmt,0);
        colRedeemBEP20(_bep20,redeemAmt);
    }


    /**
     *  Redeems accrued XVS from supplied collateral
     *  Ensures accruedXVS is greater than minVenusVal (~1e12)
     *  Sends colOwnerShare percentage to owner
     *  Collateralizes remaining XVS 
     */
    function disXVSfromInter() internal { 
        
        // find accrued xvs value
        uint accruedXVS = amtAccruedXVS();
        uint accruedXVSinUSD = Lib.getValue(accruedXVS,priceBEP20(xvs));
        
        if (accruedXVSinUSD>minVenusVal) {

            IERC20[] memory activePort = getMarketsBEP20();

            // redeem xvs
            uint balanceBeforeXVS = xvs.balanceOf(address(this));
            redeemXVS(activePort);
            uint balanceAfterXVS = xvs.balanceOf(address(this));
            uint redeemed = balanceAfterXVS - balanceBeforeXVS;
            
            // send manager share
            uint recipientFeeXVS = Lib.getValue(redeemed,colManagerShare);
            xvs.transfer(feeRecipient,recipientFeeXVS);

        }
    }


}
