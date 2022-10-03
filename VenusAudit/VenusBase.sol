// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import "./interfacesAudit/IMBNB.sol";
import "./interfacesAudit/IVBNB.sol";
import "./interfacesAudit/IVBep20.sol";
import "./interfacesAudit/IVenus.sol";
import "./interfacesAudit/IVenusOracle.sol";
import "./Lib.sol";

// give me examples of the notes/comments you'd like for me to add
// smart contract is split up into a few files
// I would like to do one file first, which the main file inherets, to
//      - get a feeling for the process
//      - see best practices to apply to my other files
//      - 


contract Venus { // 6,800 bytes --> 5500 --> 4100


    IVenus public immutable venus;

    IVBep20 public immutable vBNB;
    IVBep20 public immutable vBUSD;
    IVBep20 public immutable vXVS;

    IERC20[] internal venusTokens;

    IVenusOracle public immutable venusOracle;

    mapping(IERC20 => IVBep20) internal libraryBep20;
    mapping(IVBep20 => IERC20) internal vTokenToBEP20;

    // mainnet: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63,0xfD36E2c2a6789Db23113685031d7F16329158384,0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F,true
    // testnet: 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47,0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd,0xB9e0E753630434d7863528cc73CB7AC638a7c8ff,0x94d1820b2d1c7c7452a163983dc888cec546b77d,0x03cf8ff6262363010984b192dc654bd4825caffc,false

    // CONSTRUCTOR
    constructor(address _busd, address _wbnb, address _xvs, address _venus, address _venusOracle, bool isMainnet)  {
        if (isMainnet) {setVenusTokensMainnet();setVenusVTokensMainnet();} 
        else {setVenusTokensTestnet();setVenusVTokensTestnet();}

        venus = IVenus(_venus); //0x94d1820b2d1c7c7452a163983dc888cec546b77d
        vBUSD = IVBep20(libraryBep20[IERC20(_busd)]);
        vBNB = IVBep20(libraryBep20[IERC20(_wbnb)]); // convert to IVBNB for payable functions (mint() and repayBorrow())
        vXVS = IVBep20(libraryBep20[IERC20(_xvs)]);
        venusOracle = IVenusOracle(_venusOracle); //0x03cf8ff6262363010984b192dc654bd4825caffc
    }
    

    function setVenusTokensTestnet() internal  {
        IERC20 _wbnb = IERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); // WBNB, not actually in Venus
        IERC20 _busd = IERC20(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47); // BUSD
        IERC20 _xvs = IERC20(0xB9e0E753630434d7863528cc73CB7AC638a7c8ff); // XVS
        IERC20 _sxp = IERC20(0x75107940Cf1121232C0559c747A986DEfbc69DA9); // SXP
        IERC20 _xrp = IERC20(0x3022A32fdAdB4f02281E8Fab33e0A6811237aab0); // XRP
        IERC20 _usdc = IERC20(0x16227D60f7a0e586C66B005219dfc887D13C9531); // USDC, correct
        IERC20 _usdt = IERC20(0xA11c8D9DC9b66E209Ef60F0C8D969D3CD988782c); // USDT
        libraryBep20[_wbnb] = IVBep20(0x2E7222e51c0f6e98610A1543Aa3836E092CDe62c); // vBNB
        libraryBep20[_busd] = IVBep20(0x08e0A5575De71037aE36AbfAfb516595fE68e5e4); // vBUSD
        libraryBep20[_xvs] = IVBep20(0x6d6F697e34145Bb95c54E77482d97cc261Dc237E); // vXVS
        libraryBep20[_sxp] = IVBep20(0x74469281310195A04840Daf6EdF576F559a3dE80); // vSXP
        libraryBep20[_xrp] = IVBep20(0x488aB2826a154da01CC4CC16A8C83d4720D3cA2C); // vSXP
        libraryBep20[_usdc] = IVBep20(0xD5C4C2e2facBEB59D0216D0595d63FcDc6F9A1a7); // vUSDC, assume another BEP20
        libraryBep20[_usdt] = IVBep20(0xb7526572FFE56AB9D7489838Bf2E18e3323b441A); // vUSDT
        venusTokens = [_wbnb, _busd, _xvs, _sxp, _xrp, _usdc, _usdt];
    }

    function setVenusVTokensTestnet() internal  {
        IVBep20 _wbnb = IVBep20(0x2E7222e51c0f6e98610A1543Aa3836E092CDe62c); // WBNB, not actually in Venus
        IVBep20 _busd = IVBep20(0x08e0A5575De71037aE36AbfAfb516595fE68e5e4); // BUSD
        IVBep20 _xvs = IVBep20(0x6d6F697e34145Bb95c54E77482d97cc261Dc237E); // XVS
        IVBep20 _sxp = IVBep20(0x74469281310195A04840Daf6EdF576F559a3dE80); // SXP
        IVBep20 _xrp = IVBep20(0x488aB2826a154da01CC4CC16A8C83d4720D3cA2C); // SXP
        IVBep20 _usdc = IVBep20(0xD5C4C2e2facBEB59D0216D0595d63FcDc6F9A1a7); // USDC
        IVBep20 _usdt = IVBep20(0xb7526572FFE56AB9D7489838Bf2E18e3323b441A); // USDT
        vTokenToBEP20[_wbnb] = IERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); // vBNB
        vTokenToBEP20[_busd] = IERC20(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47); // vBUSD
        vTokenToBEP20[_xvs] = IERC20(0xB9e0E753630434d7863528cc73CB7AC638a7c8ff); // vXVS
        vTokenToBEP20[_sxp] = IERC20(0x75107940Cf1121232C0559c747A986DEfbc69DA9); // vSXP
        vTokenToBEP20[_xrp] = IERC20(0x3022A32fdAdB4f02281E8Fab33e0A6811237aab0); // vXVS
        vTokenToBEP20[_usdc] = IERC20(0x16227D60f7a0e586C66B005219dfc887D13C9531); // vUSDC, assume another BEP20
        vTokenToBEP20[_usdt] = IERC20(0xA11c8D9DC9b66E209Ef60F0C8D969D3CD988782c); // vUSDT
    }


    function setVenusTokensMainnet() internal {
        libraryBep20[IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)] = IVBep20(0xA07c5b74C9B40447a954e1466938b865b6BBea36); // WBNB
        libraryBep20[IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)] = IVBep20(0x95c78222B3D6e262426483D42CfA53685A67Ab9D); // BUSD
        libraryBep20[IERC20(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63)] = IVBep20(0x151B1e2635A717bcDc836ECd6FbB62B674FE3E1D); // XVS
        libraryBep20[IERC20(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A)] = IVBep20(0x2fF3d0F6990a40261c66E1ff2017aCBc282EB6d0); // SXP
        libraryBep20[IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c)] = IVBep20(0x882C173bC7Ff3b7786CA16dfeD3DFFfb9Ee7847B); // BTCB
        libraryBep20[IERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8)] = IVBep20(0xf508fCD89b8bd15579dc79A6827cB4686A3592c8); // ETH
        libraryBep20[IERC20(0x4338665CBB7B2485A8855A139b75D5e34AB0DB94)] = IVBep20(0x57A5297F2cB2c0AaC9D554660acd6D385Ab50c6B); // LTC
        libraryBep20[IERC20(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE)] = IVBep20(0xB248a295732e0225acd3337607cc01068e3b9c10); // XRP
        libraryBep20[IERC20(0x55d398326f99059fF775485246999027B3197955)] = IVBep20(0xfD5840Cd36d94D7229439859C0112a4185BC0255); // USDT
        libraryBep20[IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d)] = IVBep20(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8); // USDC
        // ---------
        libraryBep20[IERC20(0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf)] = IVBep20(0x5F0388EBc2B94FA8E123F404b79cCF5f40b29176); // BCH
        libraryBep20[IERC20(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402)] = IVBep20(0x1610bc33319e9398de5f57B33a5b184c806aD217); // DOT
        libraryBep20[IERC20(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD)] = IVBep20(0x650b940a1033B8A1b1873f78730FcFC73ec11f1f); // LINK
        libraryBep20[IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3)] = IVBep20(0x334b3eCB4DCa3593BCCC3c7EBD1A1C1d1780FBF1); // DAI
        libraryBep20[IERC20(0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153)] = IVBep20(0xf91d58b5aE142DAcC749f58A49FCBac340Cb0343); // FIL
        libraryBep20[IERC20(0x250632378E573c6Be1AC2f97Fcdf00515d0Aa91B)] = IVBep20(0x972207A639CC1B374B893cc33Fa251b55CEB7c07); // BETH
        libraryBep20[IERC20(0x20bff4bbEDa07536FF00e073bd8359E5D80D733d)] = IVBep20(0xeBD0070237a0713E8D94fEf1B728d3d993d290ef); // CAN
        libraryBep20[IERC20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47)] = IVBep20(0x9A0AF7FDb2065Ce470D72664DE73cAE409dA28Ec); // ADA
        libraryBep20[IERC20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43)] = IVBep20(0xec3422Ef92B2fb59e84c8B02Ba73F1fE84Ed8D71); // DOGE
        libraryBep20[IERC20(0xCC42724C6683B7E57334c4E856f4c9965ED682bD)] = IVBep20(0x5c9476FcD6a4F9a3654139721c949c2233bBbBc8); // MATIC
        libraryBep20[IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82)] = IVBep20(0x86aC3974e2BD0d60825230fa6F355fF11409df5c); // CAKE
        libraryBep20[IERC20(0xfb6115445Bff7b52FeB98650C87f44907E58f802)] = IVBep20(0x26DA28954763B92139ED49283625ceCAf52C6f94); // AAVE
        libraryBep20[IERC20(0x14016E85a25aeb13065688cAFB43044C2ef86784)] = IVBep20(0x08CEB3F4a7ed3500cA0982bcd0FC7816688084c3); // TUSD

        venusTokens = [IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56),IERC20(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63)
        ,IERC20(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A),IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c),IERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8),IERC20(0x4338665CBB7B2485A8855A139b75D5e34AB0DB94),
        IERC20(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE),IERC20(0x55d398326f99059fF775485246999027B3197955),IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d),IERC20(0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf),
        IERC20(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402),IERC20(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD),IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3),IERC20(0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153)
        ,IERC20(0x250632378E573c6Be1AC2f97Fcdf00515d0Aa91B),IERC20(0x20bff4bbEDa07536FF00e073bd8359E5D80D733d),IERC20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47),IERC20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43)
        ,IERC20(0xCC42724C6683B7E57334c4E856f4c9965ED682bD),IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82),IERC20(0xfb6115445Bff7b52FeB98650C87f44907E58f802),IERC20(0x14016E85a25aeb13065688cAFB43044C2ef86784)];
        
    }

    function setVenusVTokensMainnet() internal {
        vTokenToBEP20[IVBep20(0xA07c5b74C9B40447a954e1466938b865b6BBea36)] = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // WBNB
        vTokenToBEP20[IVBep20(0x95c78222B3D6e262426483D42CfA53685A67Ab9D)] = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD
        vTokenToBEP20[IVBep20(0x151B1e2635A717bcDc836ECd6FbB62B674FE3E1D)] = IERC20(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63); // XVS 
        vTokenToBEP20[IVBep20(0x2fF3d0F6990a40261c66E1ff2017aCBc282EB6d0)] = IERC20(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A); // SXP 
        vTokenToBEP20[IVBep20(0x882C173bC7Ff3b7786CA16dfeD3DFFfb9Ee7847B)] = IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c); // BTCB
        vTokenToBEP20[IVBep20(0xf508fCD89b8bd15579dc79A6827cB4686A3592c8)] = IERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8); // ETH
        vTokenToBEP20[IVBep20(0x57A5297F2cB2c0AaC9D554660acd6D385Ab50c6B)] = IERC20(0x4338665CBB7B2485A8855A139b75D5e34AB0DB94); // LTC 
        vTokenToBEP20[IVBep20(0xB248a295732e0225acd3337607cc01068e3b9c10)] = IERC20(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE); // XRP
        vTokenToBEP20[IVBep20(0xfD5840Cd36d94D7229439859C0112a4185BC0255)] = IERC20(0x55d398326f99059fF775485246999027B3197955); // USDT
        vTokenToBEP20[IVBep20(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8)] = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d); // USDC
        // ---------
        vTokenToBEP20[IVBep20(0x5F0388EBc2B94FA8E123F404b79cCF5f40b29176)] = IERC20(0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf); // BCH
        vTokenToBEP20[IVBep20(0x1610bc33319e9398de5f57B33a5b184c806aD217)] = IERC20(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402); // DOT
        vTokenToBEP20[IVBep20(0x650b940a1033B8A1b1873f78730FcFC73ec11f1f)] = IERC20(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD); // LINK
        vTokenToBEP20[IVBep20(0x334b3eCB4DCa3593BCCC3c7EBD1A1C1d1780FBF1)] = IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3); // DAI
        vTokenToBEP20[IVBep20(0xf91d58b5aE142DAcC749f58A49FCBac340Cb0343)] = IERC20(0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153); // FIL (p 2.67, 5.81)
        vTokenToBEP20[IVBep20(0x972207A639CC1B374B893cc33Fa251b55CEB7c07)] = IERC20(0x250632378E573c6Be1AC2f97Fcdf00515d0Aa91B); // BETH (p 0.05, venus 1550)
        vTokenToBEP20[IVBep20(0xeBD0070237a0713E8D94fEf1B728d3d993d290ef)] = IERC20(0x20bff4bbEDa07536FF00e073bd8359E5D80D733d); // CAN (p -, 1)
        vTokenToBEP20[IVBep20(0x9A0AF7FDb2065Ce470D72664DE73cAE409dA28Ec)] = IERC20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47); // ADA
        vTokenToBEP20[IVBep20(0xec3422Ef92B2fb59e84c8B02Ba73F1fE84Ed8D71)] = IERC20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43); // DOGE (weird numbers)
        vTokenToBEP20[IVBep20(0x5c9476FcD6a4F9a3654139721c949c2233bBbBc8)] = IERC20(0xCC42724C6683B7E57334c4E856f4c9965ED682bD); // MATIC
        vTokenToBEP20[IVBep20(0x86aC3974e2BD0d60825230fa6F355fF11409df5c)] = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82); // CAKE
        vTokenToBEP20[IVBep20(0x26DA28954763B92139ED49283625ceCAf52C6f94)] = IERC20(0xfb6115445Bff7b52FeB98650C87f44907E58f802); // AAVE
        vTokenToBEP20[IVBep20(0x08CEB3F4a7ed3500cA0982bcd0FC7816688084c3)] = IERC20(0x14016E85a25aeb13065688cAFB43044C2ef86784); // TUSD
    }



    // Events (for testing)
    //event VenusEvent(string description, uint number); // maybe move to Venus for priceBNB? 
    //event Message(string message);
    //event Screenshot(uint tokenBal, uint borrowBal, uint rate);


   // ----- CONTRACT ACCOUNT DATA ------ // 


    /**
    *   Returns stored balances (vToken, borrow) and stored exchange rates between bep20<-->vToken
    *   vTokenBal: vToken balance, (to get collateral amount, multiply by rate/1e18)
    *   borrowBal: underlying borrow balance
    *   rate is multiplied by 1e18
    */
    function screenshot(IERC20 _bep20) internal view returns(uint,uint,uint)  {
        (uint error,uint vTokenBal, uint borrowBal, uint rate)  = IVBep20(libraryBep20[_bep20]).getAccountSnapshot(address(this));
        require(error == 0, "!screenshot error");
        return (vTokenBal, borrowBal, rate);
    }

    /**
    *   Returns amont of underlying balance owned by the market
    */
    function getCash(IERC20 _bep20) internal view returns(uint) {
        return IVBep20(libraryBep20[_bep20]).getCash();
    }

    /**
    *   Returns collateral amount of _bep20
    */
    function colAmtBEP20(IERC20 _bep20) internal returns(uint) { // amount of BEP20 collateral on Venus
        uint _colBEP20 = IVBep20(libraryBep20[_bep20]).balanceOfUnderlying(address(this));
        return _colBEP20;
    }

    /**
    *   Returns borrowed amount of _bep20
    */
    function borAmtBEP20(IERC20 _bep20) internal returns(uint) { // amount of BEP20 borrowed from Venus
        uint _borBEP20 = IVBep20(libraryBep20[_bep20]).borrowBalanceCurrent(address(this));
        return _borBEP20;
    }

    /**
    *   Returns the amount of BEP20 to repay
    *   Sometimes not all can be repaid at once
    */
    function repaidAllowed() internal view returns(uint) { // multiple by borrow outstanding to find amount allowed
        return venus.closeFactorMantissa();
    }

    /**
    *   Returns the account liquidity (amount allowed to borrow/redeem*colFactor) after redeem or borrow
    *   _modifyBep20 is the token that is redeemed or borrowed
    *   redeemUnderlying is in vToken amount so need to redeemAmt/exchangeVBEP20   
    */
    function hypotheticalAccountLiquidity(IERC20 _modifyBep20, uint _redeemAmt, uint _borrowAmt) internal view returns(uint) { // USD value allowed to borrow 
        address vToken = address(libraryBep20[_modifyBep20]);
        uint redeemUnderlying = Lib.getAssetAmt(_redeemAmt,exchangeVBEP20(_modifyBep20)); // 1e18 BNB / 1e12 = 1e6 vBNB
        (uint error, uint liquidity, ) = venus.getHypotheticalAccountLiquidity(address(this),vToken, redeemUnderlying, _borrowAmt);
        require(error==0,"accountLiquidity error");
        uint AC = 0;
        if (liquidity>0) {AC = liquidity;}
        return AC;
    }





    function amtAccruedXVS() internal view returns(uint) {
        uint value = venus.venusAccrued(address(this));
        return value;
    }





    // ---------- VENUS MARKETS ---------- // 


    function enableCol(IERC20[] memory _portfolio) internal { // Allowing collateral and borrow of entered markets
        venus.enterMarkets(markets(_portfolio));
    }

    function disableCol(IERC20 _bep20) internal { // Allowing collateral and borrow of entered markets
        venus.exitMarket(address(libraryBep20[_bep20]));
    }


    /**
    *  Returns list of vTokens with entered markets
    */
    function getMarkets() public view returns(address[] memory) {
        return venus.getAssetsIn(address(this));
    }


    // convert type IERC20[bep20] into type address[vBep20]
    function markets(IERC20[] memory _portfolio) public view returns(address[] memory) {
        uint tokensInPortfolio = _portfolio.length;
        address[] memory market = new address[](tokensInPortfolio);
        for (uint i = 0; i < _portfolio.length; i++) {
            IERC20 token = _portfolio[i];
            market[i] = address(libraryBep20[token]);
        }
        return market;
    }


    /*
    *   Returns IERC20 addresses of tokens entered in markets
    */
    function getMarketsBEP20() public view returns(IERC20[] memory) {
        address[] memory vTokenMarkets = getMarkets();
        IERC20[] memory marketsBEP20 = new IERC20[](vTokenMarkets.length);
        for (uint i=0; i<vTokenMarkets.length; i++) {
            IVBep20 vToken = IVBep20(vTokenMarkets[i]);
            IERC20 bep20 = vTokenToBEP20[vToken];
            marketsBEP20[i] = bep20;
        }
        return marketsBEP20;
    }

    /**
    *  Returns true if _bep20 entered into market
    *  Required to post collateral (loose funds, wont get vTokens) or borrow
    *  Still able to repay borrow and redeem collateral though
    */ 
    function tokenEntered(IERC20 _bep20) internal view returns(bool) {
        address[] memory vTokensEntered = getMarkets();
        for(uint i=0; i < vTokensEntered.length; i++) {
            IVBep20 vTokenEntered = IVBep20(vTokensEntered[i]);
            if (IVBep20(libraryBep20[_bep20]) == vTokenEntered) {
                return true;
            }
        }
        return false;
    }

    // --------- TOKEN DATA: PRICE, FACTORS, RATES ---------- //



    /**
    *   Fetch prices of tokens from Venus chainlink price oracle
    */
    function priceBEP20(IERC20 _bep20) public view returns(uint256) { //have it exact BUSD
        uint price = venusOracle.getUnderlyingPrice(address(libraryBep20[_bep20]));
        return price;
    }




    // scaled by 1e18
    // multiplied by supply collateral balance to see how much value can be borrowed 
    // for example, return 800000000000000000 (0.8e18) for BUSD
    // 0.80 for BUSD, 0.60 for XVS, 0.50 for SXP
    function collateralFactor(IERC20 _bep20) internal view returns(uint) {
        (bool isListed, uint colFactor, ) = venus.markets(address(libraryBep20[_bep20]));
        require(isListed,"vToken not listed");
        return colFactor;
    }



    /**
    *   Exchange rate between bep20 and vBep20 tokens
    */
    function exchangeVBEP20(IERC20 _bep20) internal view returns(uint) {
        uint rate =  IVBep20(libraryBep20[_bep20]).exchangeRateStored();
        return rate;
    }



    // --- INTERACTIONS: REDEEM, BORROW, SUPPLY, REPAY, REDEEMCOLLATERAL --- //


    /**
    *   Redeems _bep20 from Venus of amountBEP20
    */
    function colRedeemBEP20(IERC20 _bep20, uint amountBEP20) internal { // withdrawal BNB collateral  
        require(IVBep20(libraryBep20[_bep20]).redeemUnderlying(amountBEP20) == 0, "!colWithdrawalBEP20. Try smaller amount.");
    }



    /**
    *   Borrow assets from Venus of amountBEP20
    */
    function borBEP20(IERC20 _bep20, uint amountBEP20) internal { // borrow BEP20 from Venus
        require(IVBep20(libraryBep20[_bep20]).borrow(amountBEP20) == 0, "!borBEP20. Try smaller amount.");
    }



    /**
    *   Supply _bep20 tokens to venus of amountBEP20
    *   Requires token to be entered
    */
    function colSupplyBEP20(IERC20 _bep20, uint amountBEP20) internal {  //supply BNB as collateral 
        require(tokenEntered(_bep20),"enter market.");
        //emit VenusEvent("colSupplyBEP20", amountBEP20);
        IERC20 wbnb = venusTokens[0];
        if (_bep20 == wbnb) {
            IVBNB vbnb = IVBNB(address(vBNB));
            vbnb.mint{value:amountBEP20}();
        } else {
            IVBep20 vBep20 = libraryBep20[_bep20];
            _bep20.approve(address(vBep20), amountBEP20); // approve the transfer
            assert(vBep20.mint(amountBEP20) == 0);// mint the vTokens and assert there is no error
        }
    }
    
    /**
    *   Repaying Assets to Venus
    */
    function borRepayBEP20(IERC20 _bep20,uint amountBEP20) internal returns(uint) { // repay BEP20 to Venus
        IVBep20 vBep20 = libraryBep20[_bep20];
        uint maxRepay = Lib.min(amountBEP20,borAmtBEP20(_bep20));
        uint maxRepayCloseFactor = Lib.min(maxRepay,repaidAllowed());
        //emit VenusEvent("borRepayBEP20", maxRepay);
        IERC20 wbnb = venusTokens[0];
        if (_bep20 == wbnb) {
            IVBNB vbnb = IVBNB(address(vBep20));
            vbnb.repayBorrow{value:maxRepay}();
        } else {
            _bep20.approve(address(vBep20), maxRepayCloseFactor);
            require(vBep20.repayBorrow(maxRepayCloseFactor) == 0, "!repay BEP20 error");
        }
        return maxRepayCloseFactor; 
    }


    /**
    * Redeem collateral 
    */
    function redeemXVS(IERC20[] memory _portfolio) internal { // redeem all XVS that has been earned from following markets 
        venus.claimVenus(address(this), markets(_portfolio));
    }


}


