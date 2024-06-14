#!/bin/bash

function usage { echo "Usage: cmove4.sh camera#" ; exit ;  } 

# this script will move and rename files
# in the incoming ftp directory for specified camera
# and place them in $BASE/camera#/new directory

# jpegs will be moved into snap directory

debug="on" ;
debug="off" ;

BASE="/home/mea/cams" ;
LOG=$BASE/cron.log ;
CAMLOG=$BASE/none.log ; # init this!
mydate=$( date +%Y%m%d%H%M ) ;
CAMNUM="none" ; # this is arged
mytype="mp4" ; 
DUMP="/tmp/dump/dump" ;

#echo "got here" >> /home/cameras/ddd.dat ;
me=$( whoami ) ;
#echo "$mydate me = >$me<" >> $LOG ;
#echo "$mydate USER >$USER< arg $1" >> $LOG ; exit ;

LOGTXT="$mydate cmove4.sh $CAMNUM" ;

if [ ! -z $1 ] ; then CAMNUM=$1 ; 
else echo "$LOGTXT no argument for cmove4.sh" >> $LOG ; usage ; 
fi

if [ ! -d "$BASE/$CAMNUM" ] ; then 
	echo "no $BASE/$CAMNUM directory ... fix this!" ;
	exit ;
fi
if [ ! -d $DUMP ] ; then 
	echo "$LOGTXT mkdir -p $DUMP" >> $LOG ;
	if [ $debug == "off" ] ; then mkdir -p $DUMP ;  fi
fi
if [ ! -d $DUMP ] && [ $debug == "off" ]  ; then echo "$LOGTXT can't make dump dir" >> $LOG ; DUMP="/tmp" ; fi

CAMLOG="$BASE/logs/${CAMNUM}_${mydate}.log" ;
DESTREPO="$BASE/$CAMNUM/new" ;  
if [ ! -d $DESTREPO ] ; then 
	if [ $debug == "off" ] ; then 
		mkdir $DESTREPO ; 
		echo "$LOGTXT mkdir $DESTREPO" >> $LOG ;
	fi
fi
if [ ! -d $DESTREPO ] && [ $debug == "off" ] ; then 
	echo "can't make dest repo $DESTREPO" ;
	exit ;
fi
echo "$LOGTXT mp4repo is $DESTREPO" >> $LOG ;
SRCREPO="/home/cameras/$CAMNUM" ;
#SRCREPO="/home/mea/c6" ;
if [ ! -d $SRCREPO ] ; then 
	echo "no repo $SRCREPO ... fix this!" ; 
	echo "$LOGTXT no repo $SRCREPO ... fix this!"  >> $LOG ;
	exit ; 
fi

# let's do mp4 files.  The variable is named mp4 but it can be dav 
# or whatever is defined by $mytype 	
mp4files=$( find $SRCREPO | grep "\.${mytype}$" ) ; 
if [ -z "$mp4files" ] ; then 
	echo "$LOGTXT no mp4 files in directory $SRCREPO ... exiting" >> $LOG ;
	echo "no mp4 files in directory $SRCREPO ... exiting" ; 
#	exit ;
fi

echo "$LOGTXT processing srcrepo $SRCREPO" >> $LOG ;

#---------------------- video file loop--------------------------
vfile=0 ; #flag to determine first time through this loop
MIN_MP4_SIZE=2500000 ;
for file2 in $mp4files 
do
	# check size of file
	mysize=$( stat -c %s $file2 ) ;
	if [ $mysize -lt $MIN_MP4_SIZE ] ; then mv $file2 $DUMP ; continue ; fi
	xfile2=$( basename $file2) ;
	mytime=$( echo $xfile2  | awk 'BEGIN{ FS="-"}{ print $1 }' | sed -e "s/\.//g" ) ;
#	myday=$( echo $xfile2  | awk 'BEGIN{ FS="-"}{ print $2 }' )  ;
	myday=$( stat -c%y $file2  | awk '{ print $1 }' | sed -e "s/-//g"  )  ;
#echo "myday is $myday  mytime $mytime" ; exit ;

# For some cameras we always write to day subdirs
	VIDREPO=$DESTREPO/$myday ; # $DESTREPO has been checked above
	if [ ! -d $VIDREPO ] ; then 
#		echo "mkdir $VIDREPO" ; 
		if [ $debug == "off" ] ; then 
			mkdir $VIDREPO ; 
			echo "$LOGTXT mkdir $VIDREPO" >> $LOG ;
		fi
#	else echo "$LOGTXT $VIDREPO exists" >> $LOG ;
	fi

if [ $debug == "off" ] ; then  
	mv -n $file2 "$VIDREPO/${myday}_${mytime}.${mytype}" ; 
	echo "$LOGTXT mv $file2 $VIDREPO/${myday}_${mytime}.mp4" >> $CAMLOG ;
else 
	echo "$LOGTXT mv $file2 $VIDREPO/${myday}_${mytime}.mp4" >> $CAMLOG ;
fi
#exit ;
done


#------------- now let's get the jpeg snapshots-------------------
jpegfiles=$( find $SRCREPO | grep "\.jpg$" ) ; 
if [ -z "$jpegfiles" ] ; then 
	echo "no jpeg files in $file" ; exit     ; 
fi
if [ $debug == "on" ] ; then echo "got here jpegfiles SRCREPO $SRCREPO >$jpegfiles<" ; fi
#exit ;

for file2 in $jpegfiles 
do
if [ $debug == "on" ] ; then echo "got here file2 $file2" ; fi
	if [ $CAMNUM == "camera15" ] || [ $CAMNUM == "camera9" ] ; then
		xfile2=$( echo $file2 | awk 'BEGIN{FS="/"}{print $(NF-1) "." $NF}') ;
		mytime=$( echo "${xfile2:0:8}" | sed -e "s/\.//g" ) ;
		myday=$( stat -c%y $file2  | awk '{ print $1 }' | sed -e "s/-//g"  )  ;
	elif [ $CAMNUM == "camera6" ] || [ $CAMNUM == "camera4" ] ; then
		xmytime=$( echo $file2  | awk 'BEGIN{ FS="/"}{ printf "%s%s%s" ,  $(NF-2) , $(NF-1) , $NF }'  ) ;
		myday=$( echo $file2 | awk 'BEGIN{ FS="/" }{print $6 }' | sed -e "s/-//g" ) ;
		mytime=${xmytime:0:6} ;
	elif [ $CAMNUM == "camera8" ] || [ $CAMNUM == "camera3" ] ; then
		xfile2=$( basename $file2) ;
		mytime=$( echo "${xfile2:0:8}" | sed -e "s/\.//g" ) ;
#		myday=$( stat -c%y $file2  | awk '{ print $1 }' | sed -e "s/-//g"  )  ;
		myday=$( echo $file2 | awk 'BEGIN{ FS="/" }{print $(NF-3) }' | sed -e "s/-//g" ) ;
	elif [ $CAMNUM == "camera7" ] || [ $CAMNUM == "camera2" ] || [ $CAMNUM == "camera14" ] || [ $CAMNUM == "camera11" ] || [ $CAMNUM == "camera10" ] || [ $CAMNUM == "camera12" ] ; then
		myday=$( echo $file2 | awk 'BEGIN{ FS="/" }{print $(NF-3) }' | sed -e "s/-//g" ) ;
		xfile2=$( basename $file2) ;
		mytime=$( echo "${xfile2:0:8}" | sed -e "s/\.//g" ) ;
	elif [ $CAMNUM == "camera5" ]  ; then
		myday=$( echo $file2 | awk 'BEGIN{ FS="/" }{print $(NF-5) }' | sed -e "s/-//g" ) ;
		mytime=$( echo $file2 | awk 'BEGIN{ FS="/" }{print $(NF-2)$(NF-1)$NF  }' | cut -d'[' -f1 ) ;
#echo "got here myday $myday mytyime $mytime" ;
	else 
		echo "$LOGTXT camera $CAMNUM not supported for jpegs" >> $LOG ; 
		echo "$LOGTXT camera $CAMNUM not supported for jpegs" >> $CAMLOG ; 
		exit ;
	fi

	# make destination dir if necessary
	if [ ! -d $DESTREPO/$myday ] ; then 
		echo "$LOGTXT mkdir $DESTREPO/$myday" >> $LOG ; 
#		echo "$LOGTXT mkdir $DESTREPO/$myday"  ; 
		if [ $debug == "off" ] ; then
			mkdir $DESTREPO/$myday ;
		fi
	fi

	JPEGREPO=$DESTREPO/$myday/snaps ;
	if [ ! -d $JPEGREPO ] ; then 
		if [ $debug == "off" ] ; then
			echo "$LOGTXT mkdir $JPEGREPO" >> $LOG ; 
			echo "$LOGTXT mkdir $JPEGREPO" >> $CAMLOG  ; 
			mkdir $JPEGREPO ; 
		fi
	fi

	if [ $debug == "on" ] ; then 
		echo "$LOGTXT mv $file2 $JPEGREPO/${myday}_${mytime}.jpg" >> $CAMLOG ;
		echo "$LOGTXT mv $file2 $JPEGREPO/${myday}_${mytime}.jpg" ;
	else  
		echo "$LOGTXT mv $file2 $JPEGREPO/${myday}_${mytime}.jpg" >> $CAMLOG ;
		mv -n "$file2" $JPEGREPO/${myday}_${mytime}.jpg ;
	fi

done

exit ;
