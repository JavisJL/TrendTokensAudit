# TrendTokensAudit
Code as it relates to Trend Token Audits


Deploy VenusBusinessLogic contract 

mainnet:
0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63,0xfD36E2c2a6789Db23113685031d7F16329158384,0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F,true
    
testnet:
0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47,0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd,0xB9e0E753630434d7863528cc73CB7AC638a7c8ff,0x94d1820b2d1c7c7452a163983dc888cec546b77d,0x03cf8ff6262363010984b192dc654bd4825caffc,false


The main functions to test are 

onlyOwner: 
updateVenus() 
updateOther() 

onlyManager:
distXVSfromInterest() 
disableToken(IERC20 _bep20) 
enableTokens(IERC20[] memory _tokens)
repay(IERC20 _bep20, uint _repayValue)
supply(IERC20 _bep20, uint _supplyValue)
borrow(IERC20 _bep20, uint _borrowValue)
redeem(IERC20 _bep20, uint _redeemValue) 
redeemThenRepay(IERC20 _bep20Redeem, IERC20 _bep20Repay, uint _value) 




Basically, we would like it so the manager cannot do anything to sabatoge the funds
1) Enable Tokens
    a) Tokens enabled must be part of hard-coded list
    b) Token enabled must have collateral factor above _minColFactor
    
2) Redeem and Borrow
    a) Not exceed drop tolerance
    b) Cannot exceed max exposure to market
    
3) Supply and Redeem
    a) Market must be enabled
    
4) Disable Tokens
    a) Ensure disabled tokens have a balance below minTradeVal
    b) Redeem collateral before disabling
    
    
YouTube video giving explanation of general architecture and overview of safety features:
https://youtu.be/gvXIiiYGvVs



----------------------------------------------------------------------------------------------------------------------------
-------- Script explaining the safety features in more depth (video coming soon, check channel if its public) ----------
----------------------------------------------------------------------------------------------------------------------------


We will describe each transaction, explain the safety features, show some of the code involved, as well as testing the cases the features protect against. 

Enable Tokens

Before we can supply collateral or borrow, we need to enable the tokens, just as we had to on the user interface right on Venus.

There are two safety features involved when supplying collateral. The first is…

Tokens enabled must be part of hard-coded list

When I deployed the contract, I included a list of tokens that can be enabled so the Trend Contract can interact with them on Venus as well as trade with PancakeSwap, although the pancakeSwap interactions are outside the scope of this video. 

The main reason for having a hard-coded list is to ensure that the off-chain trading bot doesn't accidentally add a high risk token, or if the manager keys ever get hacked then the hacker doesn't coordinate a pump and dump with a low volume coin. 
*show code and demo

The owner or manager cannot change the list of tokens
Token enabled must have collateral factor above _minColFactor

Collateral factors dictate how much you can borrow against a given amount of collateral. For example, BNB has a collateral factor of 80% meaning for every $1 you supply as collateral, you can borrow 80cents against it. 

Tokens that are more volatile like XVS have lower collateral factors like 60%. 

The XVS governance system votes on the collateral factors of tokens so they can change over time. 

For example, LUNA had a higher collateral factor but now its at 0% meaning it cant be used as collateral to borrow assets. These are coins we want to avoid

Therefore, to prevent from accidentally enabling such high risk token, or a hacker doing so to sabotage the funds, it will be required for a token to have have a collateral factor above _minColFactor

By default the _minColFactor is set to 50%, but the Owner has the ability to decrease this to 40%.

Redeem and Borrow

The redeem and borrow functions are under extra scrutiny because they increase the risk on Venus. 

Borrowing and redeeming assets increases the borrow to collateral ratio, and as already mentioned if it exceeds the collateral factor of the supplied assets then the account will get liquidated. 

If the contract accidentally redeems or borrows too much, exactly this will happen. 

Not exceed drop tolerance

The primary safety feature in regards to redeem and borrow is for the dropToLiquidate value to not exceed the dropTolerance.

The dropToLiquidate is an internal value in the Trend Contract that measures how much the portfolio has to drop until it hits the liquidation level.

For example, If your account has a collateral factor of 80% and you currently have $200 in collateral and borrowing $80. Your account has to drop 50% from $200 to $100 for your collateral factor to reach 80% and get liquidated. Therefore, your dropToLiquidate value is 50%. 


The dropTolerance level is an admin adjustable value in the Trend Contract to ensure we are not too close to liquidation. It sets the minimum dropToLiquidate level before further borrowing or redeeming is disabled. 

The default dropTolerance level is 25%, meaning the Trend Contract will allow redeems and borrows as long as a 25% drop in prices wouldn’t result in a liquidation. The Owner keys may lower this to a minimum of 10% or up to 100%.


Although it's outside the scope of this video. When redeeming Trend Tokens, it requires redeeming collateral from Venus. If that redeem would cause the dropToLiquidate value to exceed the dropTolerance, then the user will be unable to redeem their Trend Tokens until the portfolio rebalances to achieve lower risk. 

Cannot exceed max exposure to market

As assets being managed approach tens of millions, we might end up borrowing a large share of the available lending pools assets

For example, TRX has available assets to borrow under $1,000,000. If the Trend Contract borrowed the entire available amount, it would push the utilization rate to 100% and the borrow rate would be near 1000% per year.



We want to make sure this can’t be done accidentally by the trading bot, or intentionally by an attacker if they somehow compromised the manager keys. 


Supply and Repay

Supplying and repaying essentially decrease risk on Venus as they are opposite transactions to redeem and borrow. 

Due to this, there aren't too many risks. But there is one major risk, which is supplying collateral to a market that is not enabled. 

Market must be enabled

Although you are unable to do this via the Venus frontend, when interacting with the contracts directly it can still be done. The issue is you would lose all your money!

The Trend Contract would not receive the corresponding vToken so it would be unable to redeem collateral.

Therefore, it is vital we have it in the contract to prevent supplying assets to a market we are not enabled in.


Disable Tokens

Disabling markets removes the ability to supply collateral and borrow assets. 

Its better to disable markets instead of keeping them all enabled to save gas on calculations both when fetching data from Venus, as well as Trend Contract internal functions.

One such internal function calculates the total equity held in the smart contract, which ultimately is used to calculate the price of Trend Tokens.
 
Failure to do this properly would result in catastrophic effects including the price of Trend Tokens rapidly decreasing or increasing. 


Ensure disabled tokens have a balance below minTradeVal


If a token is disabled while holding a large collateral or borrow position on Venus, the Trend Token price calculation will ignore it and therefore under or over report the price. 

The Trend Contract would ignore those balances as it only looks at enabled markets, and therefore would fail to add the collateral value or subtract the borrowed amount from the equity. 

When users then buy Trend Tokens, they may receive too many or too few. 

Obviously this behavior is not desired, so when disabling a token it will require the balance below this minTradeVal which 

There is a case where when assets under management get really high, the minTradeVal may exceed hundreds of dollars. Therefore, theres a secondary condition where the value held in the token desired to be disabled is below $100 as well. 
Redeem collateral before disabling

This is closely related to the issue above. 

The collateral interest earnings are added to the equity amount. Venus reports the accrued XVS earnings of all enabled markets so if a market is disabled with a large accrued earnings balance,

 then it will be ignored for the Trend Token price calculation and therefore experience a sharp decrease in price. When that token is enabled again, it will experience a sharp spike in price. 

Redeeming collateral before disabling solves this issue. 


Conclusion

Those are the primary safety features when the Trend Contract interacts with Venus. 

There are some other minor features such as the values to borrow, redeem, repay, and supply must be above a value ,such as $1 to not waste gas for such small transactions. But the ones mentioned are the major features

Its possible that after having the contract audited we may add extra features or possible remove some, but for now at this stage in development, this is what we have

It ensures that the interactions are safe and in the best interest of Trend Token holders. 

If there was anything you would expect to be included in the contract that wasn’t, please feel free to email me at jay@tradeium.io or message me in the comment section below. 

Thank you for watching and see you in the next video.








