#!/bin/bash

function usage { echo "Usage: process mvkicked_dateid.sh" ; exit ; }

# This script will process the shell script
# generated from mkarray.

debug="on" ;
debug="off" ;

BASE="/home/mea/cams" ;
C6="$BASE/camera6" ;
POST="$BASE/camera6/postsort" ;
DUMP="/tmp/dump" ;
LOG="$C6/process.log" ;
mydate=$( date +%Y%m%d ) ;
mytime=$( date +%H%M ) ;
timestamp=$( date +%Y%m%d%H%M ) ;
LOGTXT="$mydate $mytime process.sh" ;

#exit ;
if [  -z $1 ] ; then usage ; fi
fname=$1 ;
echo "$LOGTEXT processing $fname" >> $LOG ;

if [ ! -d $DUMP ] ; then mkdir $DUMP ; fi
echo "$LOGTEXT process.sh postsort is $POST" >> $LOG ;
if [ ! -d $POST ] ; then 
	echo "$LOGTEXT no postsort directory $POST ... making" ; 
	mkdir $POST ; 
fi
if [ ! -d $POST ] ; then echo "$LOGTEXT procees.sh no postsort directory $POST" >> $LOG ; fi


#if [ ! -x $fname ] ; then echo "$LOGTXT no shell script $fname" >> $LOG ; exit ; fi
if [ ! -s $fname ] ; then 
	echo "$LOGTXT $fname empty " >> $LOG ; 
#	mv -n $fname $DUMP ;
	exit ; 
fi


# dirname is where mkarray was run from which is always
# the new directory now.

#dirname=$( head -1 $fname | awk 'BEGIN{FS="/"}{print $1 ; }' | awk '{print $2}' ) ;
dirname="$BASE/camera6/new" ;

dateid=$(echo $fname | awk 'BEGIN{ FS="_" } { print $2 } ' | sed -e "s/.sh$//" ; ) ;


# srcdirname is the indidual date directory from
# where mkarray was frun from

srcdirname=$dirname/$dateid ;
echo "source dirname is $srcdirname"  ; 
echo "$srcdirname exists" ; 
numvid=$(ls $srcdirname/*.mp4  | wc -l ) ;
echo "$LOGTXT number of videos before process = $numvid" >> $LOG ;

echo "$LOGTXT executing $fname" >> $LOG ;
if [ $debug == "off" ] ; then $fname ; fi
# we don't have to move fname anymore
#echo "mv -n $fname /tmp/dump" ; 
#if [ $debug == "off" ] ; then mv -n $fname /tmp/dump ; fi 
if [ ! -d $srcdirname ]  ; then
	echo "$LOGTXT source dir $srcdirname does not exist ... fix this!" >> $LOG ; 
	exit ;
fi

# destdirname is where we want to move the filtered
# mp4 files.

destdirname=$POST/$dateid ;

if [ ! -d $destdirname ]  ; then
	echo "mkdir $destdirname" ;
	mkdir -p $destdirname ;
else echo "$destdirname exists" ; 
fi

numvid=$(ls $srcdirname/*.mp4  | wc -l ) ;
echo "$LOGTXT number of videos after process $numvid" >> $LOG ;
#echo "moving videos o postsort $POST" ;

#exit ;
echo "mv -n $srcdirname/*.mp4 $destdirname" ;
if [ $debug == "off" ] ; then mv -n $srcdirname/*.mp4 $destdirname ; fi
if [ ! -d $srcdirname/snaps ] ; then
	echo "$LOGTXT shouldn't get here no snaps directory in $srcdirname" >> $LOG ; 
	exit ;
fi

if [ -d "$destdirname/snaps" ] ; then
	# snaps directory exists so move files there
	echo "$LOGTXT mv -n $srcdirname/*.jpg $destdirname/snaps" >> $LOG ;
	if [ $debug == "off" ] ; then 
		mv -n $srcdirname/snaps/*.jpg $destdirname/snaps ;
	fi
else
	# simply move the entire snaps directory
	echo "$LOGTXT mv -n $srcdirname/snaps $destdirname" >> $LOG ;
	if [ $debug == "off" ] ; then 
		mv -n $srcdirname/snaps $destdirname ;
	fi
fi
# get rid of new directory
#newnew="$BASE/camera6/new_${timestamp}" ;
#echo "$LOGTXT mv  $C6/new $C6/new_${timestamp}" >> $LOG ;
#if [ $debug == "off" ] ; then mv  $C6/new $C6/new_${timestamp} ; fi

exit ;
