# Local Variables:
# mode: makefile
# End:
# vim: set ft=make :

# this is a skeleton, remove this line and change recipes
events yyyy='':
	#!/usr/bin/env bash 
	year="{{yyyy}}"

	if [[ -z $year ]]; then
	    year=$(date +"%Y")
	fi

	mkdir -p in/$year/events
	OUTDIR=in/$year/events
	OUTFILE=$OUTDIR/$year.html
	GZOUTFILE=$OUTFILE.gz
	wget -O $GZOUTFILE https://www.atptour.com/en/scores/results-archive?year=$year
	file $GZOUTFILE
	gunzip $GZOUTFILE
	wc -l $OUTFILE

# Download links for the year
# We could compare links with existing file of links to see if any new ones. I guess current one
# would become archive each month/week ?
event_links yyyy='':
	#!/usr/bin/env bash 
	year="{{yyyy}}"

	if [[ -z $year ]]; then
	    year=$(date +"%Y")
	fi

	INDIR=in/$year/events
	INFILE=$INDIR/$year.html
	if [[ ! -f $INFILE ]]; then
		echo "$INFILE not yet downloaded"
		exit 1
	fi
	# links can be in two formats
	# link is /en/scores/archive/auckland/301/2019/results
	# link is /en/scores/current/australian-open/580/live-scores
	grep -o '/en/scores/archive.*results"' $INFILE | tr -d '"' > event_links.txt
	grep -o '/en/scores/current.*live-scores"' $INFILE | tr -d '"' >> event_links.txt
	HOST="https://www.atptour.com/"
	counter=0
	for link in $(cat event_links.txt); do
		echo link is $link
		IFS='/' read -ra ADDR <<< "$link"
		if [[ $link = *archive* ]]; then
		  YEAR=${ADDR[6]}
		  CODE="${ADDR[4]}-${ADDR[5]}"
		elif [[ $link = *current* ]]; then
		  YEAR=$(date +"%Y")
		  CODE="${ADDR[4]}-${ADDR[5]}"
		fi
		OUTFILE=in/$YEAR/events/$CODE.html
		echo $OUTFILE
		GZOUTFILE=$OUTFILE.gz
		if [[ -f $OUTFILE ]]; then
			echo $OUTFILE exists
		else
			link="${HOST}${link}"
			echo Downloading $link to $OUTFILE
			wget --header="accept-encoding: gzip" -O $GZOUTFILE $link
			if [[ -f $GZOUTFILE ]]; then
				gunzip $GZOUTFILE
			fi
			((counter++))
		fi
		echo "$counter files were downloaded"
		# check if file exists, ignore else download
	done
