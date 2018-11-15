   
### NAME
reward - reward simulator

### USAGE
       reward [OPTIONS] [TIMESTAMP] ACTION [CONTEXT]
       cat ACTIONS_FILE | reward [OPTIONS]
   
### DESCRIPTION
Reward will return the simulated reward for suplied action.
It will choose random value from uniform distribution.
Means of rewards are linearly distributed themselves.
Context is a parametric linear shift of this distribution.

### ACTION
       The ACTION is the index number of the action chosen.
   
### CONTEXT
       The CONTEXT is a space separated vector defining the context
       of given dimensionality.
   
### ACTIONS_FILE
       Lines with space separated numbers.  First is the the action
       number, followed by the context vector.  Empty lines or hash
       comments are skipped.
   
### OPTIONS
             -h  This help.
             -v  Verbose execution using STDERR.
         -a=NUM  Number of possible actions (default 2: action 1 and action 2).
         -r=NUM  Number of possible rewards (default 2: 0 and 1).
     -i=NUM,NUM  Interval of reward values (default [0,No_of_rewards-1]).
         -s=NUM  Spread of rewards distribution (default 2).
   
         -c=NUM  Length of the context vector (default 0).
        -cn=NUM  Number of context states (default 2: 0 and 1).
    -ci=NUM,NUM  Interval of context values (default [0,Context_states-1]).
   
       The mean of reward is shifted by the context.  The shift is between none to
       opposite (opposite distribution of means as without the context).
   
            -cl  Linear context with every dimension equaly important (default).
            -cc  Cascading context with every next dimension less important.
   
### VERSION
reward.0.2 (c) R.Jaksa 2018 GPLv3

