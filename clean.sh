#!/bin/bash

function usage { echo "Usage: ./clean.sh  dirname" ; exit ; }

# gets rid of night time mp4s from specified repo directory

if [  -z $1 ]  ; then usage ; exit ; fi

BASE="/home/mea/cams" ;
dirname="$BASE/camera6/$1" ;
#cd $1 ; 
THRESH=17 ; # >= to this hour will be thrown out
THRESH=18 ; # >= to this hour will be thrown out
THRESH=19 ; # >= to this hour will be thrown out
THRESH=20 ; # >= to this hour will be thrown out
THRESH=21 ; # >= to this hour will be thrown out
THRESH=22 ; # >= to this hour will be thrown out
MINTHRESH="02" ;
mydate=$( date +%Y%m%d%H ) ;
DUMP="/tmp/dump/tmp" ;
LOG="$BASE/cron.log" ;
if [ ! -d $DUMP ] ; then mkdir $DUMP ; fi
if [ ! -d $DUMP ] ; then echo "$mydate clean.sh Can't make dump $DUMP" >> $LOG ; fi 

echo "$mydate clean.sh processing $dirname" >> $LOG ;
files=$( find $dirname -name \*.mp4 ) ;
for file in $files ;
do
	mytime=$( echo $file | cut  -d'_' -f2 | sed -e "s/.mp4//" ) ;
	hour=${mytime:0:2} ;
	if [ $hour -ge $THRESH ] || [ $hour -lt $MINTHRESH ] ; then 
#		echo "got here $hour file $file" ;
#		echo "mv $file $DUMP" ;
		mv $file $DUMP ;
	fi
done

exit ;

