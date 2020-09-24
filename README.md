# flashbot

A blockchain based life form. 

It has resources in the form of at least ether and $FRY, and possibly other tokens. 

It monitors a constant product of all it's erc20s and ether balances.

It allows any external system to use it's resources and act with its authority as long as the external system leaves the product minPerc% higher than at the beginning of the transaction. 

Conclusion: This is the first system that allows for multi-dimensional flash loans and an altering bucket of liquidity.

Notes: 

This alhpa version assumes equal weightings for all erc20s.

There's likely a bunch of rounding error attacks possible atm.

State checking is a little clunky but sufficient.

It shouldn't be susceptable to dark forest attacks since it does delegate calls and the delegate call contract can be set up such that an attacker cannot easily and cost effectively clone the delegate call contract in time to execute the attack. More sophisticated attacks could later emerge in which case a booking system where the hash of the call is stored by the actor using the bot, with a deposit, followed by a call and the return of the deposit. 

Thoughts:

This could act as an invariant place holder for an x.y=k exchange. Then extremely efficient x.y=k solutions could be implemented and delegate called.

The product check itself could be abstracted to improve on x.y=k
