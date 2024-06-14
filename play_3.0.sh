#!/bin/bash

function usage { echo "Usage: play mp4dir" ; exit ; }



BASE=$PWD ;
mydate=$( date +%Y%m%d ) ;
myhour=$( date +%H%M ) ;
timestamp=$( date +%Y%m%d%H%M%S ) ;
LOGTEXT="$mydate $myhour play.sh" ;

TMP="$BASE/tmp" ;  # this must be a relative path from $BASE
if [ ! -d $TMP ] ; then mkdir $TMP ;  fi
if [ ! -d $TMP ] ; then echo "$LOGTEXT can't make $TMP ... fix this!" ; exit ; fi
if [ ! -d "$TMP/snaps" ] ; then mkdir "$TMP/snaps" ; fi
if [ ! -d "$TMP/snaps" ] ; then echo "$LOGTEXT can't make >$TMP/snaps" ; exit ; fi

if [ -z $1 ] ; then usage ; fi
REPO="$BASE/$1" ; # selected directory
if [ ! -d $REPO ] ; then echo "$LOGTEXT no repo $REPO" ; exit ; fi

#SNAPS="$REPO/snaps"  ;  # holds jpeg snapshots
## downstream code likes to know there's a SNAPS dir even if empty
#if [ ! -d $SNAPS ] ; then mkdir $SNAPS ; fi
#if [ ! -d $SNAPS ] ; then echo "$LOGTEXT can't make >$SNAPS<" ; exit ; fi

# null dir is used to collect stuff that should be deleted
# this script never deletes anything
nulldir="$BASE/nulldir" ;
if [ ! -d $nulldir ] ; then mkdir $nulldir ; fi

# directory holding selected mp4s 
# cstop name hard coded in downsteam code
SAVEDIR="$BASE/cstop" ; 

if [ ! -d $SAVEDIR ] ; then mkdir $SAVEDIR ;  fi
if [ ! -d $SAVEDIR ] ; then 
	echo "$LOGTEXT can't make >$SAVEDIR< .. fix this!"  ; exit ; 
fi


if [ -e "$BASE/filelist.dat" ] ; then rm "$BASE/filelist.dat" ; fi
#if [ ! -z $1 ] ; then 
#	REPO=$1 ;
#	if [ ! -d $REPO ] ; then echo "no repo $REPO" ; exit ; fi
#	SNAPS=$REPO/snaps ;
##	if [ ! -d $SNAPS ] ; then mkdir $SNAPS  ; fi
#else echo "Usage: play dir" ; exit ; 
#fi

#if [ ! -d $SNAPS ] ; then echo "no jpeg repo $SNAPS ... fix this!" ; exit ; fi

mytype="mp4" ; # used to support different video types
if [ -s $BASE/config.sh ] ; then source $BASE/config.sh ; fi

# the following saves groups of snippets but isn't implemented yet
function mysave() {
	srcdir=$REPO ;
	numfields=$(echo $INPUT | awk '{print NF}') ;
	if [ $numfields -eq 4 ] ; then
	        mysavedir=$(echo $MYINPUT | awk '{print $4}') ;
		snapdir=$SNAPS ;
		rsnapdir=$mysavedir/snap ;
		if  [ ! -d $rsnapdir ] ; then
			echo "$snapdir or $rsnapdir missing ... exiting" ; exit ;
		fi
#echo "mv $rsnapdir/*.jpg $snapdir"  ;
#mv $rsnapdir/*.jpg $snapdir  ;

		if [ ! -d $BASE/$mysavedir ] ; then
		        echo "$BASE/$mysavedir does not exist.  Create (y)/n" ;
		        read SINPUT  < /dev/tty ;
			if [[ $SINPUT == "y" ]] ; then
				echo "making $BASE/$mysavedir" ;
				mkdir $BASE/$mysavedir ;
			fi
	        else
			echo "should get out of here" ;
			echo "do nothing"  ; 
#			exit ;
		fi
	fi
}

## lsmp4s function may not be needed yet
#function make_lsmp4s() {
#   while read myindex mydate mysize xfile
#   do
#	if [ -z $mystart ] ; then mystart=1 ; fi
#        file=$(basename $xfile) ;
#        if [ $myindex -ge $mystart ]  ; then 
#		if [ -z "$lsmp4s" ] ; then lsmp4s=$xfile ; 
#		else lsmp4s="$lsmp4s $xfile" ;
#		fi
#        fi
#   done < $BASE/filelist.dat 
#}

# Usage: mvjpegs destdir
# destdir and destdir/snaps have been checked
# $myjpegs is global and contains a list of jpegs separated by a space
function mvjpegs() {
	if [ -z $1 ] ; then echo "$LOGTEXT no arg for mvjpegs" ;  exit ; fi
	destdir="$1" ;
	if [ ! -d $destdir ] ; then 
		echo "$LOGTEXT >$destdir< not found in mvjpegs" ; exit ; 
	fi
	if [ ! -z "$myjpegs" ] ; then
		if [ ! -d "$destdir/snaps" ] ; then mkdir "$destdir/snaps" ; fi
		for myinput_file in  $myjpegs 
		do
			mv $myinput_file "$destdir/snaps" ;
		done
	fi
}

# main input function
function myinput() { 
	# CHOOSE_TMP and CHOOSE_REPO are globals and should
	# already be populated but check anyway.

	if [ $CHOOSE_TMP == "none" ] || [ $CHOOSE_REPO == "none" ] ; then
		echo "$LOGTEXT CHOOSE_TMP or CHOOSE_REPO not populated" ;
		exit ;
	fi

	# the d is used to send mp4 and its jpegs to cstop directory
	# for next stage of processing
	echo "enter l=list d=archive v=view_video s=skip q=quit return=delete" ;
	read INPUT  ;
	# a return sends mp4 and its snaps to tmp directory
	if [ -z "$INPUT"  ]  ; then 
		# no need to "delete to tmp" if already in tmp directory
		if [ $REPO != $TMP ] ; then 
			echo "deleting $CHOOSE_REPO/$file" ; 
			mv -n $CHOOSE_REPO/$file $CHOOSE_TMP ; 
			if [ -d $TMP ] && [ -d $CHOOSE_TMP/snaps ] ; then mvjpegs $CHOOSE_TMP ; 
			else echo "shouldn't get here bad dir $TMP" ; exit 
			fi
		fi
	elif [ "$INPUT" == "v" ] ; then ffplay $CHOOSE_REPO/$file  ; loop="yes" ;
	elif [ "$INPUT" == "q" ] ; then 
		if [ -s $REPO/dfilelist.dat ] ; then 
			listdirs $REPO ;
			set_start $REPO ;
		else echo "goodbye" ; exit ; 
		fi
	# s will be show the array data now 
	elif [ "$INPUT" == "s" ] ; then echo "skipping doing nothing" ; 
	elif [ "$INPUT" == "b" ] ; then let myindex=$myindex-2 ;
	elif [[ "$INPUT" =~ ^[0-9]+$ ]] ; then myindex=$INPUT ; 
	elif [ "$INPUT" == "d" ] ; then 
		if [ ! -d $SAVEDIR ] ; then  
			# this should have been made above
#			mkdir $SAVEDIR ;
			echo "$LOGTEXT can't find savedir $SAVEDIR ... shouldn't get here" ; exit ; 
		fi
		mv $CHOOSE_REPO/$file $SAVEDIR ; # this is the .mp4 file
		# $myjpegs is global and populated for mvjpegs
		# it contains all the jpegs associated with this mp4
		# and it's populated before myinput is called
		mvjpegs $SAVEDIR ; 
	elif [ "$INPUT" == "l" ] ; then 
		echo "listing $REPO" ; 
		makelist $REPO | tee filelist.dat ;
		echo "hit q to quit" ;
		read INPUT2  < /dev/tty ;
		if [[ "$INPUT2" =~ ^[0-9]+$ ]] ; then 
		omyindex=$myindex ;
		myindex=$INPUT2 ; 
echo "myindex is now $myindex" ;
			checkfile=$( grep "^$myindex " filelist.dat) ;
			if [ -z "$checkfile" ] ; then
				echo "index out of range ... continuing" ;
				myindex=$omyindex ;
			fi
		elif [ -z  "$INPUT2"  ] ; then echo "doing nothing" ;
		elif [  "$INPUT2" == "q"  ] ; then 
			if [ -s $REPO/dfilelist.dat ] ; then 
				listdirs $REPO ;
				set_start $REPO ;
			else echo "goodbye" ; exit ; 
			fi
		fi
	elif [ ! -z $INPUT ] ; then # save it!
		if [ -d $INPUT ] ; then 
			mv "$CHOOSE_REPO/$file" "$BASE/$INPUT" ; # this is the .mp4 file
			mvjpegs "$BASE/$INPUT" ;
		else 
			echo "can't find $INPUT make?" ;
			read INPUT2
			if [[ $INPUT2 == "y" ]] ; then 
				mkdir "$BASE/$INPUT" ; 
				mkdir "$BASE/$INPUT/snaps" ;
				mv "$CHOOSE_REPO/$file" "$BASE/$INPUT" ;
				mvjpegs "$BASE/$INPUT" ;
			else echo "doing nothing for $CHOOSE_REPO/$file" ; continue ;
			fi
		fi 
	else echo "doing nothing for $CHOOSE_REPO/$file" ; continue ;
	fi
}
# mytype is always mp4 now
function makelist() {
#echo "mytype = $mytype"  ;
		if [ -z $1 ] ; then
			# $REPO is selected directory
			# regenerate the list
			ls -Hltr $REPO | grep -E [.]${mytype}$ | awk 'BEGIN{count=1}{print count" "$6"_"$7"_"$8" "$5" "$9" " ; count++ ; }'   ;
#		else
#		# we want to sort on filename for mp4s because they can have
#		# funny timestamps.
#			ls -Hl $1 | grep -E [.]${mytype}$ | awk -v dir=$1 'BEGIN{count=1}{print count" "$6"_"$7"_"$8" "$5" "$9" " ; count++ ; }'   ;
		else
#echo "arg=$1" ;
			ls -Hltr $1 | grep -E [.]${mytype}$ | awk -v dir=$1 'BEGIN{count=1}{print count" "$6"_"$7"_"$8" "$5" "$9" " ; count++ ; }'   ;
		fi
}

# if a directory only has directories list those
# and place them in dfilelist.dat
# NOTE: dfilelist.dat should be formalized better
#
#if [ ddd="true" ] ; then dddd=false ; 
CHOOSE_REPO="none" ;
CHOOSE_TMP="none" ;
SNAPS="none" ;
# $REPO is the main repositories for all dateid directories
# Usage: listdirs $REPO
function listdirs() {
	# this function will set CHOOSE_REPO and SNAPS
	# which is the dateid directory containing mp4s 
	# and its snaps subdirectory ... clear as mud?

	echo "list directories in $BASE/$REPO"      ; 
#	mydirs=$( ls -Hl $1 | grep ^d | grep -v snaps | awk -v dir=$1 'BEGIN{count=1}{print count" "$9" " ; count++ ; }' ) ;  
#	if [ -z "$mydirs" ] ; then then echo "no subdirs in $REPO either" ; exit ; 
#	else 
#	fi

	# dfilelist.dat contains a numbered list of dateid directories. 
	# This is to make it simpler to select by typing a single integer
	# instead of an entire dateid
	ls -Hl $1 | grep ^d | grep -v snaps | awk  'BEGIN{count=1}{print count" "$9" " ; count++ ; }'  | tee $REPO/dfilelist.dat  ;

	if [ ! -s $REPO/dfilelist.dat ] ; then 
		echo "$LOGTEXT no subdirs in $REPO either" ; 
		if [ -e $REPO/dfilelist.dat ] ; then rm $REPO/dfilelist.dat ;  fi
		exit ;
	fi
	echo "enter directory #" ;
	read DIRINPUT  < /dev/tty ;
	mystart=1 ;
	if [[ "$DIRINPUT" =~ ^[0-9]+$ ]] ; then mystart=$DIRINPUT ; 
	elif [ "$DIRINPUT"  == "q" ] ; then echo "$LOGTEXT quitting" ; exit ;
	fi
	chosen_dir=$( grep "^$mystart " $REPO/dfilelist.dat | awk '{ print $NF }' ) ;
	CHOOSE_REPO="$REPO/$chosen_dir" ;
	CHOOSE_TMP="$TMP/$chosen_dir" ;
	if [ ! -d $CHOOSE_TMP ] ; then mkdir $CHOOSE_TMP ; fi
	if [ ! -d $CHOOSE_TMP ] ; then 
		echo "$LOGTEXT can't make >$CHOOSE_TMP< ... fix this!" ; exit ;
	fi
	SNAPS="$CHOOSE_REPO/snaps" ;
echo "got here >$CHOOSE_REPO< >$CHOOSE_TMP< snaps $SNAPS" ;
	if [ ! -d $SNAPS ] ; then 
		echo "$LOGTEXT no snaps dir $SNAPS" ; 
		mkdir $SNAPS ;
	fi
	# $SNAPS not necessary but if it can't be made there's
	# a problem ... probably permissions ... so fix it
	if [ ! -d $SNAPS ] ; then
		echo "$LOGTEXT can't make >$SNAPS<" ; exit ;
	fi 
	if [ -d $CHOOSE_REPO   ] ; then 
		makelist $CHOOSE_REPO | tee "$BASE/filelist.dat" ;
		if [ ! -s $BASE/filelist.dat ] ; then 
			echo "$LOGTEXT no videos in $REPO" ;  
#			echo "mv -n $REPO $nulldir" ;
#			mv -n $REPO $nulldir ;
#echo "got here $?" ; exit ;
#			if [ $? -eq 0 ] ; then
#echo "mv -n $REPO $nulldir/${REPO}.${timestamp}"    ; 
#				mv -n $REPO $nulldir/${chosen_dir}.${timestamp}   ;
#			fi
		fi
	else echo "$LOGTEXT shouldn't get here chosen_dir = $chosen_dir" ; exit ; 
	fi
} # endof listdirs

# prompt user to enter a video number from filelist.dat
# Usage: set_start $REPO
function set_start() {
	if [ -z $1 ] ; then echo "$LOGTEXT SYSERR no REPO defined" ; fi
	MYREPO=$1 ;
	if [ ! -s $BASE/filelist.dat ] ; then  echo "return" ; return ; fi
	echo "enter start video" ;
	read MYINPUT  < /dev/tty ;
	mystart=1 ;
	if [[ "$MYINPUT" =~ ^[0-9]+$ ]] ; then mystart=$MYINPUT ; 
	elif [ "$MYINPUT"  == "q" ] ; then 
		if [ -s $MYREPO/dfilelist.dat ] ; then 
			listdirs $MYREPO ;
			set_start $MYREPO  ;
		else echo "quitting" ; exit ;
		fi
	else mystart=1 ;
	fi
	myindex=$mystart ;
}

#-------------------------------------------------------------------
# past all functions start of script
# first let's make a filelist.dat file 
#-------------------------------------------------------------------

makelist $REPO | tee filelist.dat ;
if [ ! -s $BASE/filelist.dat ] ; then  listdirs $REPO ;  set_start $REPO ;
else set_start $REPO ;  # prompt user to enter a video number from filelist.dat
fi

lsmp4s="" ; # this holds the a list of filenames without paths

if [ -z "$REPO" ] ; then echo "no files in $REPO" ; exit ; fi

myjpegs="none" ; # this variable will contain the sequence of snapshots
mp4loop="true" ;
myindex=$mystart ;

# mp4s will drive this loop even though 
# we see the trigger jpegs
#for file in $lsmp4s  ; 
myloop=0 ; # flag to know when first time through
while [ $mp4loop == "true" ]
do
	if [ ! -e "$BASE/filelist.dat" ] ; then 
		echo "$LOGTEXT no filelist.dat" ; exit ; 
	fi
	if [ ! -s "$BASE/filelist.dat" ] ; then 
		echo "$LOGTEXT filelist.dat empty"  ; 
		listdirs $REPO ;
		continue ; 
	fi
	file=$(grep "^$myindex " $BASE/filelist.dat | awk '{ print $NF}' ) ;
	if [ ! -e "$CHOOSE_REPO/$file" ] ; then 
		if [ $CHOOSE_REPO == $REPO ] ; then
			echo "file $CHOOSE_REPO/$file has been moved ... fix this" ; 
			let myindex=$myindex+1 ;
			exit ;
		else 
			CHOOSE_REPO=$REPO ; 
			CHOOSE_TMP=$TMP ;
			SNAPS="$TMP/snaps" ;
			if [ ! -d $SNAPS ] ; then mkdir $SNAPS ; fi
			if [ ! -d $SNAPS ] ; then 
				echo "$LOGTEXT can't make >$SNAPS<" ; exit ;
			fi
			continue ;
		fi
	fi
	if [ -z "$CHOOSE_REPO/$file" ] ; then 
		if [ -s $REPO/dfilelist.dat ] ; then 
			listdirs $CHOOSE_REPO ;
			if [  -s "filelist.dat" ] ; then set_start $CHOOSE_REPO  ; fi
			continue ;
		else echo "reached the end  $myindex" ; exit ; 
		fi
	fi
	echo "processing #${myindex} $CHOOSE_REPO/$file" ;
	if [ ! -e $CHOOSE_REPO/$file  ] ; then echo "$CHOOSE_REPO/$file not found" ; continue ; fi

	seqnum=$(echo "$file" | sed -e "s/\.mp4//" ) ;
	myyear=${seqnum:0:4} ;
	mymonth=${seqnum:4:2} ;
	myday=${seqnum:6:2} ;
	mydate=${seqnum:0:8} ;
	myhour=${seqnum:9:2}  ;
	mymin=${seqnum:11:2}  ;
	mysec=${seqnum:13:2}  ;
	myhms=${seqnum:9:6}  ;
	myepoch=$( date --date "$mymonth/$myday/$myyear $myhour:$mymin:$mysec"  +%s  ) ; 

	TMPDATE=$TMP/$mydate ;
	echo "tmp is now $TMPDATE" ;
	if [ ! -d $TMPDATE ] ; then mkdir $TMPDATE ; fi
	if [ ! -d $TMPDATE ] ; then echo "$LOGTEXT can't make >$TMPDATE<" ; exit ; fi
	if [ ! -d "$TMPDATE/snaps" ] ; then  mkdir "$TMPDATE/snaps" ; fi
	if [ ! -d "$TMPDATE/snaps" ] ; then  echo "$LOGTEXT can't make >$TMPDATE/snaps<" ; exit ; fi
	
	xmysec=$mysec ;
	loop="yes"  ;
	found=0 ; # keeps track of loop below
# now we have to find the jpegs
	while [ $loop == "yes" ] ;
	do
		# reconstruct sequence
#		jseqnum=$( echo $myepoch | awk '{print strftime("%m-%d_%H:%M:%S",$1) }'  ) ;
		jseqnum=$( echo $myepoch | awk '{print strftime("%Y%m%d_%H%M%S",$1) }'  ) ;
#echo "jseqnum=$jseqnum" ; 
#echo "jseqnum is $jseqnum" ; exit ;
#		jseqnum="$mydate-${myhour}${mymin}${mysec}" ;
		if [ ! -d $SNAPS ] ; then echo "no jpeg repo $SNAPS ... fix this!" ; exit ; fi
		jpgfname="$SNAPS/${jseqnum}.jpg" ;
		if [ -e $jpgfname ] ; then # it's a hit
			# try and get all three snaps
			# this is hard coded for now
			found=0 ;
			myjpegs=$jpgfname ;
			loop="no" ;
			let endepoch=$myepoch+2 ;
			let startepoch=$myepoch+1 ;
			seq_epoch=$startepoch ; 
			jpegloop="yes" ;
#			for (( c=$startepoch ; c<=$endepoch ; c++ )) 
			# the below loop will pick up the rest of the snapshots
			# in sequence.  myjpegs was already populated with the
			# trigger above.
			mulligan="true" ;
			while [ $jpegloop == "yes" ] ;
			do
#				jseqnum=$( echo $c | awk '{print strftime("%Y%m%d_%H%M%S",$1) }'  ) ;
				jseqnum=$( echo $seq_epoch | awk '{print strftime("%Y%m%d_%H%M%S",$1) }'  ) ;
				jpgfname="$SNAPS/${jseqnum}.jpg" ;
				if [  -e $jpgfname ] ; then # it's a hit
					myjpegs="$myjpegs $jpgfname" ;
				elif [ $mulligan == "true" ] ; then mulligan="false" ; 
				else jpegloop="no" ; # it's not a hit let's get out of here
				fi
				let seq_epoch=$seq_epoch+1 ;
			done
		fi	
		let myepoch=$myepoch+1 ;
		let found=$found+1 ;
		if [ $found -gt 9 ] ; then myjpegs="" ; loop="no" ; fi
	done

	echo "feh $myjpegs" ;
	let myindex=$myindex+1 ;
	loop="yes"  ;
	if [ -z "$myjpegs" ] ; then 
		ffplay $CHOOSE_REPO/$file ;
		myinput ;
		loop=no ;
	fi
	first=0 ;
	while [ $loop == "yes" ] ;
	do
		loop="no" ;
		if [ ! -z "$myjpegs" ] && [ $first -eq 0 ]  ; then feh $myjpegs ; fi
		first=1 ;
		myinput ;
#exit ;
	done
done

