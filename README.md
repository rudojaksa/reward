### NAME
reward - reward simulator for contextual bandits

### USAGE
       reward [OPTIONS] [TIMESTAMP] ACTION [CONTEXT]
       cat ACTIONS_FILE | reward [OPTIONS]

### DESCRIPTION
Reward provides "most" simple simulation of stochastic reward for
contextual bandits.

Reward returns the simulated reward for supplied action.
It just chooses random value from the defined uniform distribution.
Means of rewards provided for particular actions are linearly distributed.
Context, if provided, defines further linear shift of these means.

ACTION is the ID number of action to be rewarded.  Optional CONTEXT
is a space separated vector defining the context in which action was done.
TIMESTAMP can be also provided optionally.

### ACTIONS_FILE
Actions file or a stream are just lines with space separated numbers.
Optional ISO 8601 timestamp is followed by mandatory action ID, followed
by optional context vector.  Empty lines or hash comments are skipped.

### OPTIONS
             -h  This help.
             -v  Verbose execution using STDERR.
            -vw  Vowpal Wabbit output format.
   
         -a=NUM  Number of possible actions (default 2: action 1 and action 2).
         -r=NUM  Number of possible rewards (default 2: 0 and 1).
     -i=NUM,NUM  Interval of reward values (default [0,No_of_rewards-1]).
         -s=NUM  Spread of rewards distribution (default 2).
   
         -c=NUM  Length of the context vector (default 0).
        -cn=NUM  Number of context states (default 2: 0 and 1).
    -ci=NUM,NUM  Interval of context values (default [0,Context_states-1]).
   
       The mean of reward is shifted by the context.  The shift is between none to
       opposite (opposite distribution of means compare to no-context).
   
            -cl  Linear context with every dimension equally important (default).
            -cc  Cascading context with every next dimension less important.

### EXAMPLES
       reward 2 1 1
       evgen | reward
       evgen -c=3 20 | reward
   
       Full simulation loop:
       evgen -c=3 -f=log.dat | reward | context_bandit >> log.dat

### VERSION
reward-0.2 (c) R.Jaksa 2018 GPLv3

