#!/usr/bin/perl
#
# Usage: cat n1.dat | ./sortvdata.pl > n1_sort.dat
#

use warnings ;
use strict ;

my $aelimit = 800 ; # lower limit for ae

# so far only one arg allowed, ae
# this argument will switch analysis to the
# absolue pixel change matrices
my $action="" ;
if (my @args = @ARGV)    {
	$action = $args[0] ;
	if ( $action ne "ae" ) {
		print "bad action $action" ; exit ;
	} 
}

my @ndat = <STDIN> ;

my %n1hash=() ; # keyed by  row, column ; value is change number
my %n2hash=() ; # keyed by  row, column ; value is change number
my $row=1 ;
my $col=1 ;
my $n1=0 ;
my $n2=0 ;
foreach my $tmp (@ndat) {
	if ( $tmp =~ /^n1/ ) { $n1=1 ; next ;}
	elsif ( $tmp =~ /^n2/ ) { 
		$n2 = 1 ; 
		$n1 = 0 ; 
		$col = 1 ;
		$row = 1 ;
		next ;
	}
	my @items = split ( / +/ , $tmp ) ;
	my $change = int ($items[1]) ;
	my $mykey="$row-$col" ;
#print "$n1 $mykey $change\n" ; 
	if ($n1 == 1 ) {
		$n1hash{$mykey} = $change ;
	} else { $n2hash{$mykey} = $change ; }
	$col++ ;
	if ( $col == 11 ) { $col = 1 ; $row++ ; }
}

my $vthresh=10000 ;
if ($action eq "ae" ) { $vthresh = $aelimit ; }
#print " vthresh=$vthresh\n" ; exit ;
my %cols1 = () ;
my %cols2 = () ;
my $mycols=1 ;
my $myindex=1 ;
my $mythresh=15 ;

for ( my $i=1 ; $i <= 10 ; $i++ ) {
	$cols1{$i}=0 ;
	$cols2{$i}=0 ;
}
foreach my $tmp ( sort { $n1hash{$b} <=> $n1hash{$a} } keys %n1hash ) {
	my @items = split ( /-/,$tmp ) ;
#print "$tmp $n1hash{$tmp}\n" ;
	if ($items[0] < 10 )  { # skipping 10th row
		if ( $n1hash{$tmp} > $vthresh ) { $cols1{$items[1]}++ ; }
	}
	$myindex++ ;
	if ( $myindex >= $mythresh ) { last ; }
}
if ( $action ne "ae" ) { $vthresh=8000 ; }
$myindex=0 ;
foreach my $tmp ( sort { $n2hash{$b} <=> $n2hash{$a} } keys %n2hash ) {
	my @items = split ( /-/,$tmp ) ;
	my $row = $items[0] ;
#print "$tmp $n2hash{$tmp}\n" ;
	if ($items[0] < 10 ) { # skipping 10th row
		if ( $n2hash{$tmp} > $vthresh ) { $cols2{$items[1]}++ ; }
	}
	$myindex++ ;
	if ( $myindex >= $mythresh ) { last ; }
}
#exit ;
my $k1total=0 ;
my $k2total=0 ;
my $c1tot=0 ;
my $c2tot=0 ;
my $k1thresh=4 ;
my $k2thresh=4 ;
my $g6negs = 0 ;
my $first6 = 0 ;
my $first6col = 0 ;
my $k2final6 = 0 ;
my $delta_first3 = 0 ;
my $delta_second3 = 0 ;
my $delta_third3 = 0 ;
my $delta_first3_col = 0 ;
foreach my $tmp ( sort { $a <=> $b } keys %cols1 ) {
#print "$tmp\n" ;
	print "$cols1{$tmp} " ;
	if ($tmp eq "10" ) { next ; }
	$k1total += $cols1{$tmp} ;
	if ( $tmp > 0 && $tmp < 7 ) {
		$first6  += $cols1{$tmp} ;
		if ( $cols1{$tmp} > 0 ) { $first6col++ ; }
	}
	if ($tmp > 6 && $cols1{$tmp} == 0 ) { $g6negs-- ; }
	if ( $cols1{$tmp} > 0 && $tmp != 10 && $tmp <= 6 ) { $c1tot++ ; }
	if ( $cols1{$tmp} > 0 && $tmp != 10 && $tmp >  6 ) { 
		if ( $g6negs == 0 ) { $c1tot++ ; }
		elsif ($g6negs < 0 ) { $g6negs++ ; } 
	}
	if ( $cols1{$tmp} == 0 && $c1tot > 0 && $tmp <= 6) { $c1tot-- ; }
}
print "\n" ;

my %delta = () ; # keyed by col, value is col1 - col2
foreach my $tmp ( sort { $a <=> $b } keys %cols2 ) {
	print "$cols2{$tmp} " ;
	$delta{$tmp} = $cols1{$tmp} - $cols2{$tmp} ;
	if ( $tmp > 1 && $tmp < 9 ) {
		$k2total += $cols2{$tmp} ;
	}
	if ( $tmp > 4 && $tmp < 10 ) {
		$k2final6  += $cols2{$tmp} ;
	}
	if ( $cols2{$tmp} > 0 && $tmp != 10 ) { $c2tot++ ; }
}
print "\n" ;

my $delta26 = 0 ;
my $delta_last5 = 0 ;
foreach my $tmp ( sort { $a <=> $b } keys %delta ) {
	print "$delta{$tmp} " ;
	if ( $tmp > 1 && $tmp < 9 ) {
		$delta26 += $delta{$tmp} ;
	}
	if ( $tmp > 5 && $tmp < 10 ) {
		$delta_last5 += $delta{$tmp} ;
	}
	if ( $tmp > 0 && $tmp <=3 ) {
		$delta_first3 += $delta{$tmp} ;
		$delta_first3_col++ ; 
	} elsif ( $tmp > 3 && $tmp <=6 ) {
		$delta_second3 += $delta{$tmp} ;
	} elsif ( $tmp > 6 && $tmp <=9 ) {
		$delta_third3 += $delta{$tmp} ;
	}
}
print "\n" ;
print "$c1tot $k1total $c2tot $k2total $g6negs $delta26 $first6 $first6col $k2final6 $delta_first3\n" ;
if  ($k1total <= $k1thresh && $c1tot < 5) { 
	my $newthresh = 1 - $k1thresh ;
	if ( $k1total > 0 && $delta_last5 <= $newthresh ) { }
	else { print "kicked\nreason: k1total=$k1total\n" ; } 
	}
elsif ( $first6  < 2 || $first6col < 2 ) { 
	print "kicked\nreason: first6-$first6 < 2 or first6col-$first6col < 2\n" ; }
elsif ( $k2total <= $k2thresh && $c1tot < 5 ) { 
	if ( $k2final6 < 5 ) {
		print "kicked\nreason: k2total=$k2total\n" ; }
	}
elsif ( $k2total <= 1 ) { print "kicked\nreason: k2total<=1\n" ; }
elsif ( $delta26 > 9 ) { print "kicked\nreason: delta26 > 9\n" ; }
elsif ( $k2final6 == 0 ) { print "kicked\nreason: k2final6 = 0\n" ; }
elsif ( $delta_first3 <= -4 && $delta_first3_col >= 2 && $c2tot <=7 ) { 
	print "kicked\nreason: delta_first3 <= -4\n" ; }
elsif ( $delta_first3 <= -2 && $delta_second3 > 4 && $delta_third3 > 1 ) {
	print "kicked\nreason: delta_first_second_third\n" ; }

# this is the end
print "end ---------\n" ;
