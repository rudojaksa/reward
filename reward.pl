#!/usr/bin/perl
# Copyleft: R.Jaksa 2018, GNU General Public License version 3
# include "CONFIG.pl"
use v5.10; # for state
use IO::Handle qw( ); STDOUT->autoflush(1);
# ------------------------------------------------------------------------------- HELP

$HELP=<<EOF;

NAME
    reward - reward simulator for contextual bandits

USAGE
    reward [OPTIONS] [TIMESTAMP] ACTION [CONTEXT]
    cat ACTIONS_FILE | reward [OPTIONS]

DESCRIPTION
    Reward provides "most" simple simulation of stochastic reward for
    contextual bandits.

    Reward returns the simulated reward for supplied action.
    It just chooses random value from the defined uniform distribution.
    Means of rewards provided for particular actions are linearly distributed.
    Context, if provided, defines further linear shift of these means.

    ACTION is the ID number of action to be rewarded.  Optional CONTEXT
    is a space separated vector defining the context in which action was done.
    TIMESTAMP can be also provided optionally.

ACTIONS_FILE
    Actions file or a stream are just lines with space separated numbers.
    First is the the action number, followed by the context vector.
    Empty lines or hash comments are skipped.

OPTIONS
          -h  This help.
          -v  Verbose execution using CD(STDERR).
      -a=NUM  Number of possible actions CK((default 2: action 1 and action 2).)
      -r=NUM  Number of possible rewards CK((default 2: 0 and 1).)
  CC(-i=NUM,NUM)  Interval of reward values CK((default [0,No_of_rewards-1]).)
      -s=NUM  Spread of rewards distribution CK((default 2).)

      -c=NUM  Length of the context vector CK((default 0).)
     -cn=NUM  Number of context states CK((default 2: 0 and 1).)
 CC(-ci=NUM,NUM)  Interval of context values CK((default [0,Context_states-1]).)

    The mean of reward is shifted by the context.  The shift is between none to
    opposite (opposite distribution of means compare to no-context).

         -cl  Linear context with every dimension equally important CK((default).)
         -cc  Cascading context with every next dimension less important.

EXAMPLES
    CW(reward 2 1 1)
    CW(evgen | reward)
    CW(evgen -c=3 20 | reward)

    Full simulation loop:
    CW(evgen -c=3 -f=log.dat | reward | context_bandit >> log.dat)

EOF

# ---------------------------------------------------------------------------- VERBOSE

sub error {
  my $s=$_[0]; $s=~s/\n$//;
  print STDERR "$CR_$s$CD_\n"; }

sub debug {
  my $s=$_[1]; $s=~s/\n$//;
  printf STDERR "%7s: %s\n",$_[0],$s if $DEBUG; }

sub verbn { print  STDERR "\n"; }
sub verb2 { printf STDERR "$CK_%22s: %s$CD_\n",$_[0],$_[1]; }
sub verb3 { printf STDERR "$CK_%22s: %s %s$CD_\n",$_[0],$_[1],$_[2]; }

# ------------------------------------------------------------------------------- MATH

# just round the number
sub round {
  return int($_[0] + $_[0]/abs($_[0]*2 || 1)); }

# print number with max two decimal places
sub dec2 {
  my $r = sprintf("%.2f",$_[0]);
  $r =~ s/0+$// if $r =~ /\./;
  $r =~ s/\.$//;
  $r = 0 if $r eq "-0";
  return $r; }

# compare two arrays
sub areq {
  my $a1=$_[0];
  my $a2=$_[1];
  return 0 if $#{$a1} != $#{$a2};
  for(my $j=0; $j<=$#{$a1}; $j++) { return 0 if $a1->[$j] != $a2->[$j]; }
  return 1; }

# ------------------------------------------------------------------- PARSE INPUT LINE

sub isnum {
  my $s = $_[0];
  return 1 if $s eq "NaN";
  return 1 if $s =~ /^-?[0-9]+(\.[0-9]+)?$/;
  return 1 if $s =~ /^-?\.[0-9]*$/;
  return 0; }

sub parse {
  my $line = $_[0];
  my $n = 0; # in line word index
  my $a;     # parsed action
  my @c;     # parsed context
  foreach my $s (split /\s+/,$line) {
    $n++;
    next if $n==1 and $s =~ /^[0-9]+-[0-9]+-[0-9]+$/;	 # date on 1st field
    next if $n==1 and $s =~ /^[0-9]+:[0-9]+(:[0-9]+)?(\.[0-9]+)?$/; # time on 1st field
    next if $n==2 and $s =~ /^[0-9]+:[0-9]+(:[0-9]+)?(\.[0-9]+)?$/; # time on 2nd field
    $a=$s and next if not defined $a and isnum $s;
    push @c,$s and next if isnum $s;
    error "wrong field: $s"; }
  verb2 "input line","$line" if $VERBOSE;
  # verb2 "action",$a if $VERBOSE;
  # verb2 "context","@c" if $VERBOSE;
  return($a,@c); }

# ------------------------------------------------------------------------------ ARGVS
foreach(@ARGV) { if($_ eq "-h") { printhelp $HELP; exit 0; }}
foreach(@ARGV) { if($_ eq "-v") { $VERBOSE=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-d") { $DEBUG=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-cl") { $CTYPE=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-cc") { $CTYPE=2; $_=""; last; }}

our $ACTIONS = 2;
our  $SPREAD = 2;
foreach(@ARGV) { if($_ =~ /^-a=([0-9]+)$/) { $ACTIONS=$1; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-s=([0-9]*\.?[0-9]*)$/) { $SPREAD=sprintf("%f",$1); $_=""; last; }}

our $REWARDS;
our ($RMIN,$RMAX);
foreach(@ARGV) { if($_ =~ /^-r=([0-9]+)$/) { $REWARDS=$1; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-i=([0-9]+),([0-9]+)$/) { $RMIN=$1; $RMAX=$2; $_=""; last; }}

our $CONTVEC;
foreach(@ARGV) { if($_ =~ /^-c=([0-9]+)$/) { $CONTVEC=$1; $_=""; last; }}

our $CONTEXTS;
foreach(@ARGV) { if($_ =~ /^-cn=([0-9]+)$/) { $CONTEXTS=$1; $_=""; last; }}

our ($CMIN,$CMAX);
foreach(@ARGV) { if($_ =~ /^-ci=([0-9]+),([0-9]+)$/) { $CMIN=$1; $CMAX=$2; $_=""; last; }}

our $LINE;
my $gotdate;
my $gottime;
foreach(@ARGV) {
  next if $_ eq "";
  $LINE.="$_ " and $gotdate=1 and $_="" if not defined $gotdate and $_ =~ /^[0-9]+-[0-9]+-[0-9]+$/;
  $LINE.="$_ " and $gottime=1 and $_="" if not defined $gottime and $_ =~ /^[0-9]+:[0-9]+(:[0-9]+)?(\.[0-9]+)?$/;
  $LINE.="$_ " and $_="" if isnum $_; }

# wrong arguments
my @wrong;
foreach(@ARGV) { push @wrong,$_ if $_ ne ""; }
if(@wrong) {
  error;
  foreach my $arg (@wrong) { error "wrong argument: $arg"; }
  error; }

# ---------------------------------------------------------------------- REWARDS LOGIC

if(not defined $REWARDS) {
  if(defined $RMIN and defined $RMAX) { $REWARDS = int($RMAX-$RMIN+0.5); }
  else { $REWARDS = 2; }}

my ($rmax,$rmin);
if(not defined $RMIN) {
  if(defined $RMAX) { $rmin = $RMAX - $REWARDS; }
  else { $rmin = 0; }}
if(not defined $RMAX) {
  if(defined $RMIN) { $rmax = $RMIN + $REWARDS; }
  else { $rmax = $REWARDS-1; }}
$RMAX = $rmax if not defined $RMAX;
$RMIN = $rmin if not defined $RMIN;

# ---------------------------------------------------------------------- CONTEXT LOGIC

our $CDEF;
$CDEF = 1 if defined $CONTEXTS or defined $CMIN or defined $CMAX;

if(not defined $CONTEXTS) {
  if(defined $CMIN and defined $CMAX) { $CONTEXTS = int($CMAX-$CMIN); }
  else { $CONTEXTS = 2; }}

my ($cmax,$cmin);
if(not defined $CMIN) {
  if(defined $CMAX) { $cmin = $CMAX - $CONTEXTS; }
  else { $cmin = 1; }}
if(not defined $CMAX) {
  if(defined $CMIN) { $cmax = $CMIN + $CONTEXTS; }
  else { $cmax = $CONTEXTS; }}
$CMAX = $cmax if not defined $CMAX;
$CMIN = $cmin if not defined $CMIN;

$CTYPE = 1 if not defined $CTYPE;

# ------------------------------------------------------------------------------- CORE

# reward: 0 1 2 ...
my ($r0,$rn) = ($RMIN,$RMAX); my $rd = $rn-$r0; my $rs = $rd/($REWARDS-1);

# action: 1 2 3 ...
my ($a0,$an) = (1,$ACTIONS);  my $ad = $an-$a0;

# context: 0 1 2 ...
my $cc = 0; 
my @c_c0; my @c_cn; my @c_cd; my @c_cs;
our %C;
$C{dim} = 0;	 # context dimensionality
$C{n} = 0;	 # current context dimensionality
$C{c0} = \@c_c0; # columns min values
$C{cn} = \@c_cn; # columns max values
$C{cd} = \@c_cd; # columns ranges
$C{cs} = \@c_cs; # columns steps for unit
$C{dim} = $CONTVEC if defined $CONTVEC;

# return the context step
sub cstep {
  my $j = $_[0];
  my $cs;

  # context steps, where every dimension is equal
  if($CTYPE == 1) {
    $cs = 1.0 / $C{dim} / ($C{cd}->[$j] + 1.0); }

  # context steps, where every next dimension is equal to just one part of previous
  if($CTYPE == 2) {
    if($j==0) { $cs = 1.0 / ($C{cd}->[$j] + 1.0); }
    else { $cs = $C{cs}->[$j-1] / ($C{cd}->[$j] + 1.0); }}

  return $cs; }

# init
if(defined $CDEF) {
  my $cs;
  for(my $j=0; $j<$C{dim}; $j++) {
    $C{c0}->[$j] = $CMIN;
    $C{cn}->[$j] = $CMAX;
    $C{cd}->[$j] = $C{cn}->[$j] - $C{c0}->[$j];
    $C{cs}->[$j] = cstep $j;
    $cs .= int($C{cs}->[$j]*100+0.5)."% "; }
  verb2 "context steps",$cs if $VERBOSE; }

if($VERBOSE) {
  verb2 "$ACTIONS actions","$a0..$an (range $ad)";
  verb2 "$REWARDS rewards","$r0..$rn (range $rd, step $rs)";
  verb2 "spread","$SPREAD"; }

# check whether the event is valid
sub check {
  my $a = $_[0];
  my $cp = $_[1];

  # action
  my $a2 = dec2($a);
  verb2 "action",$a2 if $VERBOSE;
  error "action $a2 is out of range [$a0,$an]" if $a<$a0 or $a>$an;
  error "action is decimal" if $a2 =~ /\./;

  # context type
  state $ct = 0;
  if($VERBOSE and not $ct) {
    my $s;
    $s = "linear" if $CTYPE == 1;
    $s = "cascading" if $CTYPE == 2;
    verb2 "context type",$s;
    $ct = 1; }

  # context dimensionality
  if(not defined $CONTVEC) {
    my $cd = scalar @{$cp};
    if($cd != $C{dim}) {
      $C{dim} = $cd;
      verb2 "context dimensionality",$C{dim} if $VERBOSE; }}
  else {
    state $cdok = 0;
    verb2 "context dimensionality",$C{dim} if $VERBOSE and not $cdok;
    $cdok = 1; }

  # required context dimensionality
  my $cn = scalar @{$cp};
  $C{n} = $C{dim};
  $C{n} = $cn if $cn < $C{n};

  # context ranges
  my $c2;
  if(not defined $CDEF) {
    my ($cx,$cs);
    my @cdo = @{$C{cd}};
    for(my $j=0; $j<$C{n}; $j++) {
      my $cj = $cp->[$j];
      $c2 .= "$cj ";
      $C{c0}->[$j] = $cj if $cj < $C{c0}->[$j] or not defined $C{c0}->[$j];
      $C{cn}->[$j] = $cj if $cj > $C{cn}->[$j] or not defined $C{cn}->[$j];
      $C{cd}->[$j] = $C{cn}->[$j] - $C{c0}->[$j];
      $C{cs}->[$j] = cstep $j;
      $cx .= "[$C{c0}->[$j],$C{cn}->[$j]] ";
      $cs .= int($C{cs}->[$j]*100+0.5)."% "; }

    # context ranges changed
    if(not areq($C{cd},\@cdo)) {
      verb2 "context intervals",$cx if $VERBOSE;
      verb2 "context steps",$cs if $VERBOSE; }}

  verb2 "context",$c2 if $VERBOSE and @{$cp}; }

# compute the mean reward for action
sub mean {
  my $a = $_[0];
  my $cp = $_[1];
  check $a,$cp;

  # context shift
  my $cs;
  if(@{$cp}) {
    $cs = 0;
    for(my $j=0; $j<=$C{n}; $j++) {
      $cs += ($cp->[$j] - $C{c0}->[$j]) * $C{cs}->[$j]; }
    verb2 "context shift",int($cs*100+0.5)."%" if $VERBOSE; }

  # mean
  my $m = (1.0-$cs*2.0)*$rd/$ad*($a-$a0) + $r0 + $rd*$cs;

  # verbose
  my $m0s;
  if($VERBOSE and defined $cs) {
    my $m0 = $rd/$ad*($a-$a0) + $r0; # without the context shift
    $m0s = " (".dec2($m0)." without context)" if $m0 != $m; }
  verb2 "linear mean",dec2($m).$m0s if $VERBOSE;
  return $m; }

# compute the mean reward for action without considering context
sub mean_nocontext {
  my $a = $_[0];
  my $c = $_[1];
  check $a,$c;
  my $m = $rd/$ad*($a-$a0) + $r0;
  verb2 "linear mean",$m if $VERBOSE;
  return $m; }

# distribute the reward in distribution
sub dist {
  my $a = $_[0];
  my $s = $a + rand($SPREAD) - $SPREAD/2;
  verb2 "uniformly distributed",dec2($s) if $VERBOSE;
  return $s; }

# quantize the reward
sub quant {
  my $r = $_[0];
  my $q = ($r-$r0)*($REWARDS-1)/$rd + $r0;
  my $n = round($q)*$rs;
  $n = $RMAX if $n>$RMAX;
  $n = $RMIN if $n<$RMIN;
  verb2 "quantized reward",dec2($n) if $VERBOSE;
  return $n; }

# compute the reward
sub reward {
  return quant dist mean $_[0],$_[1]; }

# ---------------------------------------------------------------------- ARGUMENTS RUN

if(defined $LINE) {
  my ($a,@c) = parse $LINE;
  my $r = reward $a,\@c;
  print "$r\n"; }

# ---------------------------------------------------------------------- STREAMING RUN

if(not defined $LINE) {
  while(<STDIN>) {
    my $s = $_;
    $s =~ s/\n$//;

    # skip empty lines
    if($s =~ /^\h*$/) { next; }

    # comments
    elsif($s =~ /^\h*\#/) {
      print "$s r1\n";
      next; }

    # data
    else {
      my ($a,@c) = parse $s;
      my $r = reward $a,\@c;
      print "$s $r\n"; }
    print "\n" if not $_=~/\n$/; }}

# -------------------------------------------------------------------------------- END
