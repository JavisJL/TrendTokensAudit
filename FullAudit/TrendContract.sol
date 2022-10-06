// SPDX-License-Identifier: ISC
pragma solidity ^0.8.14;

import "./mBNB.sol";
import "./VenusX.sol";
import "./PancakeX.sol";

// ** complete
// * in progress
// ! skip
//
//
// 1)* Test and Optimize where possible
//      - test dropTolerance upon redeem
//      - test gas differences with and without events
//      - make events similar to last version (easier frontend integration)
//          - maybe remove mBNB supply from TrendTokenPrice? 
//
// 2) Prevent Venus/Pancake functions with insufficent balances
//      - so I know what the error is
//
// 3) Require all pancakeslippage upon deposit/redeem to be within limit? 
//     - or maybe just the coin bein deposited? 
//
// 4) Change where send performanceFee is! 
//
// 5) Prevent anyone from minting Trend Tokens
//
// 6) Add Pancake trade fee to owner
//
// 7) Security
//     - race conditions, https://www.setprotocol.com/pdf/peckshield_audit_report.pdf page 15
//
// 8) Vote on Portfolio
//      - enable and disable functionality is handled by the Trend Token voting mechanism
//
// 9) PancakeCost needs to work with outside portfolio tokens so enable will work! 
//
// 10) Re-add Swap require statement and isBestPath require statement
//
//
// 12)** Need a way to redeem-->borrow if stuck under dropToLiquidate?
//      - actually, could just decrease the dropToLiquidate value? 
//          wont always be able to do this? 
//
// 13)** Make sure minTradeVal doesnt get too large so disable token doesnt have too large balane
//
// 14) Add checkActiveToken() back to contracts 

// Suggestions/Questions:
//  - backup oracle? 
//  - Pancake bridge to Ethereum
//  - is current and stored equity needed seperate? 
//  - maybe add reserves from collateral (need governance?)
//      - trend token holders can vote! I need to verify
//  - have a seperate list of tokens that can be used to buy trend tokens? 
//  - option to override fee?
//  - input minimum fees or mimimum returned amount from user side (set default) 
//      - feeTolerance: minTrendOut = valueIn * (1 - feeTolerance) / trendPrice
//
// --- Next Version --- //
//
// 8) When users buy a token
//      - get from Uniswap or PancakeSwap bridges
//
// 5) Written Unit/Systems Tests
// 6) Extneral Written Tests
// 7) External Audit
//
// --- Future Version --- //
//
// 1) Production Considerations
//      - set Venus to true
//          - sets mainnet address for interTokens
//      - set PancakeSwap to true
//          - change interTokens in PancakeSwap
//          - change slippage to 1% not 100% (just keep manager limit to 1%)
//      - change maxRedeemMT
//
// 2) Add Governance Token 
//      - buyback upon rebalances
//          - use XVS to buy BNB --> buy MSWAP --> burn
//      - discount on deposits
//          - would need contract to be able to hold MGW, and trade to BNB or BUSD if above above some threshold 
//      - ability to change Manager
//      - owner is set to 3 addresses 
//      - distribute to margin token holders sometimes?
//      - Add token buyback program. Free deposits. 
//
//
// 3) Add Manager backup security system (multi-sig)
//      - MSW: tokens vote to change manager (spread amongst 10 wallets), need a 50% vote (need to hack 5 accounts)
//      - manager is just one wallet
//      - owner is another wallet
//      - governance: ability to change manager, 
//
//
// 4) Cross-Chain Bridge
//      - lock Trend Tokens on BSC, mint on Ethereum
//      - burn Ethereum tokens to unlock BSC Trend Tokens
//      - create Trend_Top5 / ETH pool on Uniswa
//          - if prices vary, profit for arbitragers
//      - ETH, ethereum --> Trend Tokens, ethereum; instead of
//        ETH, ethereum --> ETH, bsc --> BNB, bsc --> Trend Tokens, bsc
//      - Multichain uses the AnyswapV4Router
//      - https://bscscan.com/address/0xd1c5966f9f5ee6881ff6b261bbeda45972b1b5f3#code
//      - could also use third party DEX's like Exodus for ETH/BTC swaps? 
//
//
// 5) StableTokens
//      - holds many stablecoins
//      - if one looses peg, it will sell into others (mean revert)
//              - 
//      - it will incure trading fees, but will earn collateral for staking interest
//          - staking will be across Venus and others? 
//      - the earnings go to a treasury that has limited access to maintain the peg
//              - earnings pay for trading fees
//                  - some earnings go to Owner
//              - they pay NO performance fees
//      - it can be used to buy and sell Trend Tokens FREE!!!!!!!
//          - therfore no Utility Token
//      - underlying stablecoins can be redeemed at any moment (USDT, BUSD, USDC, etc)
//      - there would be no UST equivilent to mint tokens to maintain peg 
//      -? could Trend Tokens sell Stable Tokens to 
//      - Stable tokens is different from Trend Tokens in that it has a treasury that is not 
//      included in the stableTokenToUSD price and therefore redemption fee
//          - minor change to the token price function to 
//      - have the treasury a balance in the contract of supply? 
//      - need some way for Stable Tokens to benefit Trend Tokens and vice versa
//          - would this mean some shared responsability? 
//      - value is $1 or maximum value of underlying! 
//
//
// 6)* Automated web3.py Trend Token bot (working on this now)
//      - monitors the state of the smart contract
//      - executes rebalances for trend tokens
//
// 7) Interestingly, BlockSec was able to rescue $3.8 million from the exploiters with an "internal system" that can detect and front-run hacking incidents using off-chain arbitrage bots called flashbots, it told The Block in a Twitter message
//

// TRNT testnet: 0x7E3788A04a7DaD297d4cEe1720485A97C7d64135
// TREND mainnet: 0xA1c8beEd5D21B8D5A06DBCAa5A21fF60E5Fe0288


contract Trend_BNBXd is VenusBNBX, PancakeBNBX { 

    // Admin Addresses
    address public owner; // sets and receives fees, assigns owners/managers, 
    address public manager; // sets deposit and rebalance settings
    address public feeRecipient;

    // Token Addresses
    IMBNB public immutable mbnb;
    IERC20 public immutable wbnb;
    IERC20 public immutable busd;
    IERC20 public immutable xvs;


    // updateFees
    uint public managerTF = 0.005e18; //10; //
    uint public internalTF = 0.0005e18;
    uint public performanceFee = 0.10e18; // on gains of mTokenATH
    uint public colManagerShare = 0.25e18; //2500; // 25% owners share of collateral interest 


    // (updateDeposits)
    uint public dropTolerance = 0.10e18; // trigger rebalance if drop tolerance exceeded     borrowedUSD / ()
    uint public pancakeFeeTolerance = 0.01e18; // max difference between Venus and PancakeSwap
    uint public limitSupply = 1000000e18; // 1M Trend Tokens

    // update Venus
    bool public enabledVenus = true;
    uint public minVenusVal = 1e9;
    uint public maxVenusVal = 10000e18;
    uint public minColFactor = 0.5e18; 
    uint public maxExposure = 0.10e18;


    // update Pancakeswap
    bool public enabledPancake = true;
    uint public roundTripSec = 3600; // min ~1hrs/round trip trades
    uint public minTradeVal = 1e12;
    uint public maxTradeVal = 10000e18;
    // uint public tradeSlip; // on PancakeBNBX.sol

    // Contract changes only 
    uint[] public tradeTimestamps;
    uint[] public tradeValues;
    uint public trendTokenATH = Lib.PRICE_DEN; // max price of Margin Token in BUSD


    // Production Events

    // DEPOSITS AND WITHDRAWALS

    // Active Events
    event PerformanceFee(uint trendTokenStart, uint oldTrendTokenATH); // mint Transaction should emit event
    event TrendTokenPrice(uint time, uint trendTokenUSD, uint mBNBsupply);
    //event Deposits(IERC20 _depositBep20, uint _sellAmtBEP20);
    //event Redeems(IERC20 _redeemBep20, uint _sellAmtTrendToken);
    event vCurrent(IERC20[] activePort, uint[] prices, uint[] con,uint[] col,uint[] bor, uint Equity); // maybe add string of "ETH" for exampple
    //event Prices(uint[] prices);
    event Deposits(uint pancakeFee,uint managerFee);
    event Redeems(uint pancakeFee,uint managerFee);
    event Portfolio(uint[] portfolio);


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

    // -------- CONSTRUCTOR ------------- //   

    // updated chainlink price oracle! 0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F
    // find updated addresses here: https://github.com/VenusProtocol/venus-config/blob/kkirka/update-contract-addresses/networks/mainnet.json
    // updated chainlink: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63,0xfD36E2c2a6789Db23113685031d7F16329158384,0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F,0x10ED43C718714eb63d5aA57B78B54704E256024E,0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73

    // sept 11 w/ trend (mainnet): 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63,0xfD36E2c2a6789Db23113685031d7F16329158384,0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F,0x10ED43C718714eb63d5aA57B78B54704E256024E,0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73

    // sept 11 w/ trend (testnet): 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47,0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd,0xb9e0e753630434d7863528cc73cb7ac638a7c8ff,0x94d1820b2d1c7c7452a163983dc888cec546b77d,0x03cf8ff6262363010984b192dc654bd4825caffc,0xd99d1c33f9fc3444f8101754abc46c52416550d1,0x6725F303b657a9451d8BA641348b6761A6CC7a17

    // 0x5bF351B3DF2be25B42b0Ac0321978f70426EF199

    // 37134 after remove onlyOwner (
    constructor(address _busd, address _wbnb, address _xvs, address _venus, address _venusOracle, address _pancakeRouter, address _pancakeFactory) 
    VenusBNBX(_busd, _wbnb,_xvs,_venus,_venusOracle, true) 
    PancakeBNBX(_pancakeRouter,_pancakeFactory, true) {
        owner = msg.sender;
        manager = msg.sender;
        feeRecipient = msg.sender;
        mBNB _mbnb = new mBNB();
        mbnb = IMBNB(_mbnb);
        wbnb = IERC20(_wbnb);
        busd = IERC20(_busd);
        xvs = IERC20(_xvs);
        IERC20[] memory startPort = new IERC20[](3);
        startPort[0] = busd;
        startPort[1] = wbnb;
        startPort[2] = xvs;
        enableCol(startPort); // run function upon deployement
    }

    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! turn back on for mainnet
    receive() external payable {}


    // -----   ADMIN FUNCTIONS & VARIABLES ------------- //

    // --- OWNER 

    //transferOwnership(address _owner)
    //transferManagers(address _manager,address _feeRecipient) 
    //updateDeposits(uint256 _dropTolerance, uint _limitSupply, uint _tradeFeeThresVal)
    //updateFees(uint256 _ownerTF,uint _colShare, uint _performanceFee)
    //updateRebalSettings(uint _portfolioUpdateLimit, uint _minTradeUSD, uint _tradeSlip, bool _managerRebalEnabled) 

    /**
    * owner: change owner and manager wallet
    *        updates deposits, fees, and rebalance settings
    */
    //function transferOwnership(address _owner) onlyOwner external {
    //    owner = _owner;
    //}

    /**
    * manager: ability to update portfolio and rebalance
    * feeRecipient: wallet performance fee and collateral share go to
    */
    function transferManagers(address _manager,address _feeRecipient) onlyOwner external {
        manager = _manager;
        feeRecipient = _feeRecipient;
    }

    /**
    *   dropTolerance: % drop before redeems are disabled
    *   limitSupply: maximum amount of Trend Tokens to be minted. Stops deposits
    *   tradeFeeThresVal: USD value to calculate exact swapping fees. Otherwise flat 2%.
    */
    function updateDeposits(uint256 _dropTolerance, uint _pancakeFeeTolerance, uint _limitSupply) onlyOwner external  {
        require(_dropTolerance >= 0.10e18 && _pancakeFeeTolerance<0.05e18 ,"!updateDeposits");
        dropTolerance = _dropTolerance; // dropToLiquidate must be above dropTolernace
        pancakeFeeTolerance = _pancakeFeeTolerance; // pan
        limitSupply = _limitSupply; // true to allow deposits of BNB and buys of Trend Token
    }
    /**
    *   ownerTF: fees paid upon buy or sell Trend Token
    *   colShare: % of collateral earnings that go to feeReceipient
    *   performanceFee: % of new all time high price gains in Trend Tokens paid to feeRecipient
    */
    function updateFees(uint _managerTF, uint _internalTF, uint _colManagerShare, uint _performanceFee) onlyOwner external { 
        require(_managerTF <= 0.02e18 && _internalTF<= 0.005e18 && _performanceFee<=0.30e18 && _colManagerShare<=0.75e18,"!updateFees");
        // send performance fee
        (uint trendTokenPriceUSD,) = trendTokenToUSD(currentEquity());
        uint mintMBNB = calculatePerformanceFee(trendTokenPriceUSD, mbnb.totalSupply());
        sendPerformanceFee(mintMBNB, trendTokenPriceUSD);
        //require(_colManagerShare<0.50e18  && _colBuyBackShare<0.50e18,"col share exceeds 100%");
        managerTF = _managerTF; //0.25% 
        internalTF = _internalTF; //0.25% 
        colManagerShare = _colManagerShare; // share of collateral interest that goes to Owner 
        performanceFee = _performanceFee;
    }

    /**
    *   portfolioUpdateLimit: number of seconds allowed between rebalances
    *   minTradeUSD: minimum amount of USD to be traded in a rebalance 
    *   tradeSlip: the % tolerance per trade, includes slippage and trade fee
    *   managerRebalEnabled: true if manager is able to rebalance 
    */

    // &&_maxMarketShare<=0.25e18
    // _maxMarketShare
    function updateVenus(uint _minVenusVal, uint _maxVenusVal, uint _minColFactor, uint _maxExposure, bool _enabledVenus) onlyOwner external {
        require(_minVenusVal >= 1e12 && _maxVenusVal <= 100000000e18 && _minColFactor>=0.4e18 && _maxExposure <= 0.50e18,"invalid Venus inputs");
        minVenusVal = _minVenusVal; // min amount to borrow,repay,redeem,supply
        maxVenusVal = _maxVenusVal;
        minColFactor = _minColFactor; // min collateral factor to enable token
        maxExposure = _maxExposure;
        enabledVenus = _enabledVenus;
    }


    function updatePancake(uint _tradeSlip, uint _minTradeVal, uint _maxTradeVal, uint _roundTripSec, bool _enabledPancake) onlyOwner external {
        require(tradeSlip<=200 && _minTradeVal>=1e18 && _maxTradeVal<=10000000e18 && _roundTripSec>=3600,"invalid inputs");
        tradeSlip = _tradeSlip;
        minTradeVal = _minTradeVal;
        maxTradeVal = _maxTradeVal;
        roundTripSec = _roundTripSec; // seconds between manager rebalance. Set no limit? 
        enabledPancake = _enabledPancake;
    }



    // Manager


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


    // Frontend Aid

    function lastRebalance() external view returns(uint) {
        return tradeTimestamps[tradeTimestamps.length - 1];
    }

    function trendPriceFrontend() public view returns(uint,uint) {
        (,,,,,uint storedEquityUSD) = storedEquity();
        return trendTokenToUSD(storedEquityUSD);
    }

    /**
    *   Consumes deposited token and amount
    *   Returns the estimated amount of Trend Tokens to send to user, and the managerFee
    */
    function estAmountOutTrendToken(IERC20 _bep20, uint _depositedAmtBEP20) external view returns(uint,uint,uint) {
        (uint trendTokenPriceUSD,) = trendPriceFrontend();
        return amountOutTrendToken(_bep20,_depositedAmtBEP20,trendTokenPriceUSD);
    }

    /**
    *   Consumes deposited token and amount
    *   Returns the estimated amount of Trend Tokens to send to user, and the managerFee
    */
    function estAmountOutBEP20(IERC20 _bep20, uint _depositedAmtTrendToken) external view returns(uint,uint,uint) {
        (uint trendTokenPriceUSD,) = trendPriceFrontend();
        return amountOutBEP20(_bep20,_depositedAmtTrendToken,trendTokenPriceUSD);
    }


    // ----- PROTOCOL DEPOSITS AND WITHDRAWALS   ------ //

    // --------- TREND TOKEN PRICES ---------- // 

    /**
    *   Returns amount of Trend Token to mint and send to Manager 
    */
    function calculatePerformanceFee(uint trendTokenPrice, uint trendTokenSupply) internal view returns(uint) {
        uint gainATH = trendTokenPrice - trendTokenATH; // (1.5e18 - 1.0e18) = 0.5e18
        uint feeAmt = Lib.getValue(gainATH,performanceFee); // 0.5e18 * (2000/10000) = 0.5e18 * 20% = 0.10e18
        uint targetPrice = trendTokenPrice - feeAmt; // 1.5e18 - 0.10e18 = 1.4e18 (price after fee)
        uint mintPercent = Lib.getAssetAmt(trendTokenPrice,targetPrice) - Lib.PRICE_DEN;// (1.5e18*1e18/1.4e18) - 1e18 = 0.0714e18 (should be 0.0714%)
        uint mintMBNB = Lib.getValue(trendTokenSupply,mintPercent); // 100e18 * 0.0714e18 / 1e18 = 7.14e18 mBNB 
        return mintMBNB;
    }

    /**
    *   Send performance fee to manager
    */
    function sendPerformanceFee(uint _mintMBNB, uint _trendTokenPrice) internal {
        if (_mintMBNB>0) {
            mbnb.mint(feeRecipient, _mintMBNB); // mint and send 10.52e18 margin tokens to owner (decreasing value 1.041%)
            emit PerformanceFee(_trendTokenPrice,trendTokenATH);
            trendTokenATH = _trendTokenPrice; // update 
        }
    }


    /**
    *   calculate the Trend Token Price
    *   deducts perfromance fee and adds share of xvs   
    */
    function trendTokenToUSD(uint _equityInUSD) internal view returns(uint,uint) {  

        uint price = Lib.PRICE_DEN; // starting condition
        uint supplyTrendToken = mbnb.totalSupply();
        uint mintTrendToken; uint poolValXVS;

        if (supplyTrendToken > 0) {

            price = Lib.getAssetAmt(_equityInUSD,supplyTrendToken);

            uint accruedXVS = amtAccruedXVS();
            if (accruedXVS>0) { // add pools share of XVS to equity
                uint poolAmtXVS = Lib.getValue(accruedXVS,Lib.PRICE_DEN-colManagerShare);
                poolValXVS = Lib.getValue(poolAmtXVS,priceBEP20(xvs));
                price = Lib.getAssetAmt(_equityInUSD+poolValXVS,supplyTrendToken);
            }

            if (price > trendTokenATH) { // account for outstading performance fee
                mintTrendToken = calculatePerformanceFee(price, supplyTrendToken);
                price = Lib.getAssetAmt(_equityInUSD+poolValXVS,supplyTrendToken);
            }

            price = Lib.getAssetAmt(_equityInUSD+poolValXVS,supplyTrendToken+mintTrendToken);
        }

        return (price,mintTrendToken);

    }



    /**
    *   outTokenInVal: USD vale of tokenOut after trading _tokenIn of _valIn using bestPath pancakeRoute
    *   slippageVal: USD value of slippage after roundTrip/2 
    *   returns the true pancakePrice (remove fee/slippage) and value in slippage
    */
    function pancakePriceAndSlippage(IERC20 _tokenIn, IERC20 _tokenOut,  uint _valIn) public view returns(uint,uint) {
        uint amtIn = Lib.getAssetAmt(_valIn,priceBEP20(_tokenIn));
        (,uint outTokenAmt, uint oneWaySlipPerc) = highestOutPath(amtIn, address(_tokenIn), address(_tokenOut));
        require(oneWaySlipPerc <= pancakeFeeTolerance,"pancakeFeeTolerance exceeded.");
        outTokenAmt = Lib.getValue(outTokenAmt,Lib.PRICE_DEN + oneWaySlipPerc); // add slippage/fees back to ignore its effects
        uint outTokenInVal = Lib.getValue(outTokenAmt,priceBEP20(_tokenOut));
        uint slippageVal = Lib.getValue(outTokenInVal,oneWaySlipPerc);
        return (outTokenInVal, slippageVal);
    }


    /**
    * Calculates the total cost from pancake for trading _dep20 of _valueIn 
    * to the allocations currently held in this Trend Contract
    * Returns fees in percents (ex,0.01e18 for 1%)
    */
    function pancakeCost(IERC20 _bep20, uint _valueIn) public view returns(uint) {
        (IERC20[] memory activePort,,uint[] memory conVals,uint[] memory colVals,,uint equityUSD) = storedEquity();
        
        uint cost = 0;

        if (equityUSD>minTradeVal) {
            
            for (uint i=0; i<activePort.length; i++) {

                uint allocationPercent = Lib.getAssetAmt(conVals[i]+colVals[i],equityUSD);
                uint valIn = Lib.getValue(_valueIn,allocationPercent);
                
                if (valIn>minTradeVal) {
                    
                    if (_bep20 != activePort[i]) {
                        (uint outVal, uint slipVal) = pancakePriceAndSlippage(_bep20, activePort[i], valIn);
                        cost += Lib.abs(int(valIn) - int(outVal)) + slipVal; 
                    }
                
                } else {
                    cost += Lib.getValue(valIn,0.005e18);
                }
            }  
        }

        uint pancakePerc = Lib.getAssetAmt(cost,_valueIn);
        require(pancakePerc <= pancakeFeeTolerance,"pancakeFeeTol Cost exceeded.");
        return pancakePerc;
    }

    function managerTradeFee() internal view returns(uint) {
        uint managerFee = managerTF;
        return managerFee;
    }

    function totalFees(IERC20 _bep20, uint _inValue) public view returns(uint,uint,uint) {
        uint pancakeCostPerc = pancakeCost(_bep20, _inValue);//pancakeTradeLoss( _bep20, _amtInBEP20);
        uint managerFeePerc = managerTradeFee();
        uint totalFee = pancakeCostPerc + managerFeePerc;
        return (totalFee,pancakeCostPerc, managerFeePerc);
    }

    // 36,568
    //



    // --- Fee Functions --- //



    /**
     * Input tokena and managerFee in 0.10e18 (for 10%)
     * 1 TREND allows you to buy 1 Trend Token with 50% off fees

     */
    function sendDepositFee(IERC20 _token, uint _sellAmtBEP20, uint _managerFee) internal {
        uint amtFee = Lib.getValue(_sellAmtBEP20,_managerFee);
        if (_token == wbnb) {payable(feeRecipient).transfer(amtFee); //----- different
        } else {_token.transfer(feeRecipient, amtFee); }
    }


    /**
    *   returns output amount of Trend Token, total fee, pancakeFee, and managerfee
    */
    function amountOutTrendToken(IERC20 _bep20, uint _amtInBEP20, uint _trendPriceUSD) internal view returns(uint,uint,uint) {
        //(uint venusPrice, uint priceSlippageDeposit ,) = priceSlippage(_bep20,_amtInBEP20);
        uint venusPrice = priceBEP20(_bep20);
        uint inValue = Lib.getValue(_amtInBEP20,venusPrice);

        // fees
        (uint totalFee, uint pancakeDepositCost, uint managerFee) = totalFees(_bep20, inValue);

        uint inValueAfterFee = Lib.getValue(inValue, Lib.PRICE_DEN - totalFee);
        uint outAmt = Lib.getAssetAmt(inValueAfterFee,_trendPriceUSD);

        return (outAmt, pancakeDepositCost, managerFee);
    }

    /**
    * Checks if token is an active token
    * Returns index if requirement satisfied
    */
    function checkActiveToken(IERC20 _bep20) internal view {
        bool tokenInPort = tokenEntered(_bep20);
        require(tokenInPort,"Token not enabled");
    }


    /**!! changed
     * consumes _token and _sellAmtBEP20 from client side application
     * requires Trend Token total supply is below limitSupply
     * accepts sold BEP20 token
     * calculates and transfers fees to owner
     * collateral remaining sold BEP20
     * mints and transfers Trend Tokens
     * rebalances if borrow amount exceeds set borrow factor
     * _feeTolerance: pancakeFees + tradeFees (1%
     */
    function depositBEP20(IERC20 _depositBep20, uint _sellAmtBEP20) public {
        // Requirements
        checkActiveToken(_depositBep20);

        // Receive Deposit Tokens
        if (_depositBep20 != wbnb) {_depositBep20.transferFrom(msg.sender, address(this), _sellAmtBEP20);} 

        // Calculate Trend Token Amount and Manager Fee to Send
        //uint[] memory prices = pricesView(); emit Prices(prices);

        // used to be currentEquity
        uint equity = currentEquity();
        uint priceDepositToken = priceBEP20(_depositBep20);
        uint equityBeforeDeposit = equity - Lib.getValue(_sellAmtBEP20,priceDepositToken);
        (uint trendTokenPrice,uint mintMBNB) = trendTokenToUSD(equityBeforeDeposit); 
        (uint trendTokenAmt, uint pancakeFee ,uint managerFee) = amountOutTrendToken(_depositBep20,_sellAmtBEP20,trendTokenPrice);
        //(uint trendTokenAmt, uint pancakeFee,uint managerFee, uint priceSlippageRedeem)

        // Send Fees and Mint Trend Token
        sendPerformanceFee(mintMBNB,trendTokenPrice);
        sendDepositFee(_depositBep20, _sellAmtBEP20,managerFee);
        //require(_minTrendTokenOut<trendTokenAmt,"insufficient output Trend Token");
        mbnb.mint(msg.sender, trendTokenAmt);// mint and send Margin Token to Trader (after fees) 

        // Collateral Remaining Deposit Tokens
        uint supplyAmt = contractBal(_depositBep20);
        uint supplyVal = Lib.getValue(supplyAmt,priceDepositToken);
        venusRequirements(_depositBep20,supplyVal);
        colSupplyBEP20(_depositBep20, supplyAmt);

        uint supplyMBNB = mbnb.totalSupply();
        require(supplyMBNB < limitSupply,"Max Supply Exceeded.");
 
        //emit Deposits(_depositBep20, _sellAmtBEP20);
        emit TrendTokenPrice(block.timestamp, trendTokenPrice, supplyMBNB);
        emit Deposits(pancakeFee, managerFee);
    }


    /**
    *   Payable function for buying Trend Tokens with BNB
    */
    function depositBNB() external payable {
        depositBEP20(wbnb, msg.value);
    }


    // --- REDEEM FUNCTIONS  --- //


    function amountOutBEP20(IERC20 _bep20, uint _amtInTrendToken, uint _trendPriceUSD) internal view returns(uint,uint,uint) {
        uint venusPrice = priceBEP20(_bep20);
        uint inValue = Lib.getValue(_amtInTrendToken,_trendPriceUSD);

        // fees
        (uint totalFee, uint pancakeRedeemCost, uint managerFee) = totalFees(_bep20, inValue);

        uint inValueAfterFee = Lib.getValue(inValue, Lib.PRICE_DEN - totalFee);
        uint outAmt = Lib.getAssetAmt(inValueAfterFee,venusPrice);

        return (outAmt, pancakeRedeemCost, managerFee);
    }


    /**
     * consumes _token (to be redeemed) and redeemAmt (redeem collateral) from redeemBEP20()
     * checks min amount, max amount, and if liquidity risk allowance will be exceeded
     * redeem desired collateral if all checks are satisfied
     */
     // this contract would be called earlier, using pre-netDep 
    function redeemAndSendCol(IERC20 _redeemBep20, uint _redeemAmt) internal {

        // Checks BEP20 redeem amount exceeds minimum
        uint minRedeemBEP20 = Lib.getValue(exchangeVBEP20(_redeemBep20),10); // divides by 1e18 as required
        require(_redeemAmt>minRedeemBEP20,"Redeem too small.");

        // Checks BEP20 redeem amount below collateral
        uint collateralBEP20 = colAmtBEP20(_redeemBep20);
        require(_redeemAmt < collateralBEP20,"Redeem another token.");

        uint redeemValue = Lib.getValue(_redeemAmt,priceBEP20(_redeemBep20));
        venusRequirements(_redeemBep20,redeemValue);
        checkSafeLiquidLevels(_redeemBep20,_redeemAmt,0);
        colRedeemBEP20(_redeemBep20,_redeemAmt);

        // transfers redeemed collateral to User
        if (_redeemBep20 == wbnb) {
            payable(msg.sender).transfer(_redeemAmt); 
        } else {
            _redeemBep20.transfer(msg.sender, _redeemAmt); 
        }
    }

    /**
    *
    */
    function redeemBEP20(IERC20 _redeemBep20, uint _trendTokenAmt) external { // change back to external
        // Calculate amount to redeem and manager fee
        
        //uint[] memory prices = pricesView(); emit Prices(prices);
        // used to be current Equity
        uint currentEquityUSD = currentEquity();
        
        (uint trendTokenPrice,uint mintMBNB) = trendTokenToUSD(currentEquityUSD);
        (uint redeemAmtBEP20,uint pancakeFee ,uint managerFee) = amountOutBEP20(_redeemBep20,_trendTokenAmt,trendTokenPrice);
        // (uint redeemAmtBEP20, uint pancakeFee,uint managerFee,uint priceSlippageRedeem) 

        // Transfer and Burn Trend Token
        sendPerformanceFee(mintMBNB,trendTokenPrice);
        mbnb.transferFrom(msg.sender, address(this), _trendTokenAmt); // send Margin Token from User to Contract (need approval) 
        uint amtManagerFee = Lib.getValue(_trendTokenAmt,managerFee);
        mbnb.transfer(feeRecipient, amtManagerFee);
        mbnb.burn(mbnb.balanceOf(address(this)));

        // Checks Requirements, Redeem Collateral, Sends to User
        redeemAndSendCol(_redeemBep20,redeemAmtBEP20); // checks requirements and redeems collatearl

        // Events
        //emit Redeems(_redeemBep20, _trendTokenAmt);
        emit TrendTokenPrice(block.timestamp, trendTokenPrice, mbnb.totalSupply());
        emit Redeems(pancakeFee, managerFee);
    }



    //--- REBALANCE FUNCTIONS ----//


    /**
    *   Used to fetch contract balances
    */
    function contractBal(IERC20 _token) internal view returns(uint) {
        if (_token == wbnb) { return address(this).balance;
        } else { return _token.balanceOf(address(this));}
    }



    function currentEquity() internal returns(uint) {  // returns current balances (uint)
        //int[] memory prices = pricesUpdateX();

        IERC20[] memory activePort = getMarketsBEP20();

        uint activePortLen = activePort.length;
        uint[] memory conVals = new uint[](activePortLen);
        uint[] memory colVals = new uint[](activePortLen);
        uint[] memory borVals = new uint[](activePortLen);
        uint[] memory prices = new uint[](activePortLen);
        uint assetValSum = 0; uint borrowValSum = 0;

        for (uint i = 0; i < activePortLen; i++) {

            // fetch token and price
            IERC20 token = IERC20(activePort[i]);
            uint tokenToUSD = priceBEP20(token);
            prices[i] = tokenToUSD;

            // contract balances
            uint _contractBal = contractBal(token);
            uint contractVal = Lib.getValue(_contractBal,tokenToUSD);
            conVals[i] = contractVal;

            // collateral values
            uint collateralVal = Lib.getValue(colAmtBEP20(token),tokenToUSD);
            colVals[i] = collateralVal;

            // borrow values
            uint borrowVal = Lib.getValue(borAmtBEP20(token),tokenToUSD);
            borVals[i] = borrowVal;
            
            assetValSum += contractVal + collateralVal;
            borrowValSum += borrowVal; 
        }
        uint netEquity = assetValSum - borrowValSum;
        emit vCurrent(activePort,prices,conVals,colVals,borVals,netEquity); // maybe add string of "ETH" for example

        return netEquity;
    }



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
            (uint tokenBal, uint borrowBal, uint rate) = screenshot(token);

            // contract balances
            uint _contractBal = contractBal(token);
            uint contractVal = Lib.getValue(_contractBal,tokenToUSD);
            conVals[i] = contractVal;

            // collateral values
            uint collateralAmt = Lib.getValue(tokenBal,rate);
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



    // -------  REBALANCE HELPER FUNCTIONS  -------- //

    // security concerns
    //      - what if _acctLiquidity too high for redeemCollateral and borrowAssets within incVenusRisk?
    //      - incVenusRisk gets value externally from rebalanceSingle()


    // --- Increase Venus Risk --- //


    /**
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
    *   Safety parameters for all Venus functions ensure the _bep20 market is entered 
    *   and value is within [minVenusVal, maxVenusVal]
    */
    function venusRequirements(IERC20 _bep20, uint _value) internal view {
        require(tokenEntered(_bep20) && _value >= minVenusVal && _value <= maxVenusVal && enabledVenus," Venus Req.");
    }


    /**
    *   Ensures contract is not borrowing too much relative to available cash
    */
    function sufficientMarket(IERC20 _bep20, uint _borrowVal) internal view {
        (, uint borrowBal, ) = screenshot(_bep20);
        uint exposureValue = Lib.getValue(borrowBal,priceBEP20(_bep20))+_borrowVal;
        uint marketValue = Lib.getValue(getCash(_bep20),priceBEP20(_bep20));
        uint allowedExposure = Lib.getValue(marketValue,maxExposure);
        require(exposureValue < allowedExposure, "Venus exposure exceeded.");
    }


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
    *   Redeems _bep20Redeem of _value then repays token _bep20Repay
    *   There is a chance contract could get stuck if beyond venusRequirements()
    *   and therefore unable to redeem to repay and reduce the risk
    *   This function always reduces liquidity. Use in case contract is below safe liquid levels
    *   and unable to redeem funds to repay (lower liquidity) 
    */
    function redeemThenRepay(IERC20 _bep20Redeem, IERC20 _bep20Repay, uint _value) onlyManager external {
        venusRequirements(_bep20Redeem,_value);
        venusRequirements(_bep20Repay,_value);
        // redeem collateral
        uint redeemAmt = Lib.getAssetAmt(_value,priceBEP20(_bep20Redeem));
        colRedeemBEP20(_bep20Redeem,redeemAmt);
        // repay asset
        uint repayAmt = Lib.getAssetAmt(_value,priceBEP20(_bep20Repay));
        borRepayBEP20(_bep20Repay, repayAmt);
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


    //  ------ EXECUTE TRADES

    /**
    *   Makes sure tokens in path are inVenus and valid paths
    */
    function checkValidPath(address[] memory _path) internal view {
        for (uint i=1; i<_path.length; i++) { 
            address indexToken = _path[i]; address previousToken = _path[i-1];
            checkActiveToken(IERC20(indexToken)); checkActiveToken(IERC20(previousToken)); 
            require(validPath(previousToken, indexToken) && _path.length<=3,"!checkValidPath");
        }
    }


    /**
    *   removes first element in the tradeTimestamps and tradeValues
    */
    function removeFirst() internal {
        for (uint i=0; i<tradeValues.length-1; i++) { 
            tradeTimestamps[i] = tradeTimestamps[i+1]; 
            tradeValues[i] = tradeValues[i+1]; 
        }
        tradeTimestamps.pop();
        tradeValues.pop();
    }


    /**
    * calculate USD trades in the past hour... or % of equity in X hours
    * delete trades past that many hours ago
    * enforce limit of 1 round trip every 12 hours (43,200 seconds)
    */
    function tradedValueInWindow() internal returns(uint) {

        // sums the trade value within roundTripSeconds
        uint tradeValueInWindow = 0;
        uint[] memory tradeStamps = tradeTimestamps;
        uint[] memory tradeVals = tradeValues;
        uint roundTripSeconds = roundTripSec;
        
        for (uint i=0; i<tradeStamps.length; i++) {

            uint tradeSecAgo = block.timestamp - tradeStamps[i];

            if (tradeSecAgo > roundTripSeconds) { removeFirst();
            } else { tradeValueInWindow += tradeVals[i];}
        }
        return tradeValueInWindow;
    }

    //event TradedValue(uint value);
    //function tradedValue() public {
    //    emit TradedValue(tradedValueInWindow());

    //}


    function sendInternalTradeFee(IERC20 _token, uint _amtFee) internal {
        if (_token == wbnb) {payable(feeRecipient).transfer(_amtFee); //----- different
        } else {_token.transfer(feeRecipient, _amtFee); }
    }


    // trades
    // - up to pancakeThres (1e12)
    // - slippageTolerance (2%)
    function executeTrade(uint sellValue, address[] memory _path) onlyManager external {
        // check requirements
        require(enabledPancake,"trades disabled");
        require(sellValue>minTradeVal && sellValue<maxTradeVal,"invalid sellValue.");
        checkValidPath(_path);
        uint equity = currentEquity(); 
        require(tradedValueInWindow()+sellValue < equity*2,"Trade timeout.");


        uint priceIn = priceBEP20(IERC20(_path[0]));
        uint sellAmt = Lib.getAssetAmt(sellValue,priceIn);

        uint amtFee = Lib.getValue(sellAmt,internalTF);
        sendInternalTradeFee(IERC20(_path[0]), amtFee);

        uint sellAmtAfterFee = sellAmt - amtFee;

        uint priceOut = priceBEP20(IERC20(_path[_path.length-1]));
        uint priceOutToIn = Lib.getAssetAmt(priceOut,priceIn);
        buyTokenSellExactToken(_path,sellAmtAfterFee, priceOutToIn);
        tradeTimestamps.push(block.timestamp);
        tradeValues.push(sellValue);

    }


}


