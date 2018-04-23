Challenge description:
Design a system that provides a market for betting on a football match. Users should be able to open a binary market (e.g. will Barcelona or Real Madrid win the next El Classico) and a transaction that should be sent for either case (e.g. recording market statistics in the blockchain logs). Subsequently the system should open up a market where anyone can buy a stake for or against the proposal. Once the result is known the market should be settled fairly and the appropriate transaction should be executed.
 
Describe how you would go about implementing this system for the Ethereum network. Do as much of the relevant coding as you can.
 
Be prepared to discuss your learning experience as well as the economic incentives at play, potential security vulnerabilities, malicious use cases, scaling concerns, shortcomings in design and gas trade offs.

Solution:
I will write a smart contract, defining the functionalities defined above in our contract. Later we need to wrap this in a js business logic, and make appropriate calls from there according to when a game is created, bets are placed, game is evaluated than winners can be paid.

Best to keep the business logic on the backend, ie Nodejs rest api calls, and only expose sending bets logic from a frontend framework like reactjs. When winners are set and withdraw is possible we should do some sort of security check to make sure correct person is logged in to do the withdrawal. 

In the end, the solidity contract  will have to do calls such as:

createGame, placeBet (as many as possible from many accounts), evaluate (to get the results), setWinners (called from a controled environemnt, ie js business logic of our app when evaluation is completed, withdraw (to send the prize to correct winners, gain from js)

Github address for the solidity solution: https://github.com/lupelius/footballBet

Instructions to run:

var bet = FootballBet.deployed();
var events = bet.allEvents(function(error, log){ if (!error) console.log(log.args); });
var accounts = ['0xb6460d8c1dac5e8e36f61e77ce92d8be6fa9a204', '0x089a6e9e19cc9e2109ef7d743336497acc078a8e', '0x6db9bbeab27b0645586b94c4cc850caaae0260d8', '0xc8af04d396b695ce61f85325f754c3bfe8aca006', '0xc5df1da6c8211978203a6a480a53580c49648e7c'];

bet.createGame.sendTransaction('152250', {'from':accounts[2], value:5000000000000000000});
bet.placeBet.sendTransaction('0', {'from':accounts[2], value:1000000000000000000});
bet.placeBet.sendTransaction('1', {'from':accounts[3], value:1000000000000000000});
bet.placeBet.sendTransaction('0', {'from':accounts[4], value:1000000000000000000});
bet.evaluate.sendTransaction({'from':accounts[2]});
bet.setWinners.sendTransaction({'from':accounts[2]});
bet.withdraw.sendTransaction({'from':accounts[3]});



Points learned:

Strings are not supported on solidity, for defining proper strings, its best to use third party libraries like the one attached. We need to treat strings building with immutability just like every other 
Something like OpenZeppelins SafeMath library needs to be used for numbers, ie incrementing or decrementing numbers, if the value goes above max or below min, the attacker could be allowed to spend more than they have, being maxed out. 
Visibility matters according to use cases, external is cheaper and safer than public, as public needs to copy all the arguments to memory causing more gas spend, private and internal are either the function can be called within the contract, or within the hierarchy.
Remix does very well with syntaxial corrections which leads to cleaner code
TheDAO hack - how we need to reduce a users balance before actually sending the eth for claiming a prize, ie a won binary market, as in parallel programming paradigm doing the opposite may cause the attacker to trigger many withdraws with msg.sender.call.value(_amount)(). Use transfer or require send instead of any other way of transferring the prize for best practice msg.sender.transfer(_value) / require(msg.sender.send(_value));
Oraclize is a very useful library to call third party data like live exchange parities or match results via rest apis or other services

Learning resources:
https://ethereum.stackexchange.com/questions/305/what-are-common-pitfalls-or-limitations-when-coding-in-solidity
https://remix.ethereum.org
http://solidity.readthedocs.io/en/v0.4.21/
https://medium.com/loom-network/how-to-secure-your-smart-contracts-6-solidity-vulnerabilities-and-how-to-avoid-them-part-1-c33048d4d17d
https://github.com/chrisdotn/footballBet/blob/master/contracts/footballBet.sol




