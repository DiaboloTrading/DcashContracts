Diabolo.io Copy Trading Platform

# DCASH Stacking Performance & Staking reward protocol  

- [ABSTRACT](#abstract)
- [DCASH STACKING PERFORMANCE](#diabolofundperformance)
  - [The role of the DCASH STACKING PERFORMANCE smart oracle](#theroleofthediabolofundperformancesmartoracle)
  - [Calculation of the performance of DFP](#calculationoftheperformanceofdfp)
- [DIABOLO STAKING PROTOCOL](#diabolostakingprotocol)
  - [Calculation of the Individual Monthly Staking Reward (IMSR)](#calculationoftheindividualmonthlystakingreward(imsr))
  - [The Individual Monthly Staking Reward (IMSR) is calculated as following](#theindividualmonthlystakingreward(imsr)iscalculatedasfollowing)


## I.	ABSTRACT

Diabolo is a crypto trading platform which offers various investment solutions such as generating revenues from a passive copy trading service involving Diabolo’s whitelisted professional traders. 

Diabolo team wants to share, with its community, best trading performance made by Diabolo professional traders. Diabolo will revolutionize the way people trade and invest on crypto assets. 

In this perspective, Diabolo developped an innovative staking reward protocol which aims to allows stakeholders to benefit from monthly gain made by the Diabolo Fund Performance (DFP). Monthly gains will be paid out in the form of stablecoin $ (DAI). To be eligible, stakeholders must delegate their DCASH tokens to a dedicated staking Diabolo smart contract. 

![Image of Gobal Overview](https://github.com/crypto4all/Diabolo/blob/main/Diabolo%20Fund%20Performance%20and%20Staking%20mechanism%20Overview.png)
 
## II.	DIABOLO STACKING PERFORMANCE  

The Diabolo STACKING Performance (DFP) will replicate automatically the performance made by Diabolo’s top traders. At the start of the DFP, initial invested amount (FTA) will be deposited on Diabolo’s corporate Business Account (opened on partnered crypto exchange platform such as Binance) which will be used to initiate the investment strategy (copy trading). The DFP will replicate the global performance of whitelisted top traders from Diabolo.io

Currently all traders on Diabolo’s platform could only replicate best trader’s performance through manually process trading. It will allow automate replication of trader’s performance by using a smart oracle plugged into Diabolo’s corporate BA.

The DFP is calculating the real performance of the fund in real time by being connected to DEX (like Uniswap/Balancer) and CEX (Like Binance/Kucoin).
The amount managed by Diabolo team is composed of 30 % of the ICO public sale  collected amount in ETH and 20% of the DCASH Token managed on the Liquidity Reserve.


### A.	The role of the Diabolo Fund Performance smart oracle

	The smart oracle corresponds to a smart contract which interacts outside the blockchain network with an external source of data. Smart oracle will be able to get information needed by the smart contract to process internal actions or verifications. In this way, smart contracts can interact with real time trading information.

Diabolo Fund Performance smart oracle is connected to Diabolo’s corporate Business Account to consult the deep market and real time information about trading activity of the amount invested. Smart oracle is putting the concept by placing the external code execution in the oracles’ hands considering it as a trustless source of information. 


![Image of Smart Oracle](https://github.com/crypto4all/Diabolo/blob/main/Diabolo%20smart%20oracle.png)
 
### B.	Calculation of the performance of DFP

Each early month, the initial invested capital [FTA(i)] deposited is snapshotted and placed on the secondary market to be traded by our Diabolo whitelisted traders during the entire month. At the end of the month a second snapshot will be made to determine the investment amount available [FTA(f)]. The difference between [FTA (i)] and [FTA (f)] will represent the the gain (G) to be distributed between Dcash staking holders in the form of stablecoin (DAI). 
T
he monthly performance gain (G) is calculated based on the average performance of each whitelisted traders on Diabolo.io during one-month period.

G = FTA (f) – FTA (i)                                  with G < 0 or G >= 0

In case that G < 0 the Fund Performance have realized a net loss. 
In case that G = 0 the Fund Performance have realized zero profit and zero loss.
In case that G > 0 the Fund Performance have realized a net profit.

The performance of DFP is represented in percentage which reflect a global metric of the performance. 
G % = [ (FTA (f) – FTA (i)) / FTA (i) ] * 100

**Example: On 1st January the initial initial invested capital [FTA(i)] worth 400 000 $ and at the end of the month 31th January the final investment amount available [FTA(f)] worth 414 732 $. 
G = 414 732 – 400 000 = 14 732 $
G% = [(414 732 – 400 000) / 400 000 ] * 100 = 3,683 %**

**The net performance of the DFP generated during January represent positive performance of 3,683 % which corresponds to 14 732 $ gain.**


## III.	DIABOLO STAKING PROTOCOL 

Diabolo has decided to create a staking mechanism for the community to give it the possibility to stake their Dcash token and be eligible to receive a part of the gain generated by the Diabolo Fund Performance. 
The term “staking” means to lock a certain amount of DCash token for a specific period. In our case the staking model is based on monthly period (from the 1st to the 30th/31th).
At every moment, user could withdraw (unstake) his DCASH tokens. However, the user will be unable to claim monthly gains generated by the Fund Performance during the staking period.
The eligibility is correctly applied for the upcoming month when the amount staked is considering before the start of the next month (1st). When a staking month is already started it is no longer possible to apply to be eligible, only the upcoming month will be considering for the eligibility. 

### A. Calculation of the Individual Monthly Staking Reward (IMSR)

The staking smart contract is playing an important role for the distribution of monthly gain generated by the DFP. As previously explained, we must propose a new interesting way to redistribute fairly 100% of the gain “G” to Dcash stakeholder as a staking reward but exclusively distributed in stablecoin (DAI). 
The decision to distribute it on stablecoin is relatively simple, user keep his Dcash valorization and he is rewarded for locking them on the staking smart contract when the DFP is generating profits.
In case of negative performance, users will not be rewarded, the loss will be imputed directly to DFP through the initial invested capital [FTA(i)] for which it’s deducted.

### B. The Individual Monthly Staking Reward (IMSR) is calculated as following

IMSR = (IMDS * TMSR) / TMDS

*IMSR: Individual Monthly Staking Reward amount in stabelcoin DAI ($)*
*IMDS: Individual Monthly Dcash Staked amount in DCASH Token*
*TMSR: Total Monthly Gain Reward = Gain (G) in Stablecoin DAI ($)   if only G > 0  in other case TSR = 0*
*TMDS: Total Monthly Dcash Staked amount in DCASH Token*

**Example : On 18th November 2020 Richard decided to stake 10 000 DCASH Token which represents his Individual Monthly Dcash Staked amount (IMDS).
To be eligible for December month in order to get his Individual Monthly Staking Reward (IMSR), Richard has to keep IMDS amount until the end of the month (31th December 2020) otherwise he will lose the right to claim his IMSR.**

**When the 1st December is reached the Total Monthly Dcash Staked (TMDS) amount is frozen with 200 000 DCASH from all IMSD eligible wallets. On 31st December 2020, the Total Monthly Gain Reward (TMSR) is calculated and reached 20 000 $.
At the end of the first staked month, Richard decide to claim his IMSR and get 1000 $ (DAI) which is calculated regarding the above formula:**

**IMSR = (IMDS * TMSR) / TMDS
IMSR (Richard) = (10 000 * 20 000) / 200 000 = 1000 DAI ($)**
