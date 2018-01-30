#!/bin/bash

# This script downloads data from the genomics core facility server (forge) to my personal pc. 
# Then it uploads that data to the begg server.


# target directory on begg server
targetdir="/DATA/users/shared/design/DNA/lowcoverage/bam/"

#### get list of files from forge site

# get the index.html file from forge:
forge_url="http://forge/userdata/sbjuFoF27Tga2k0tAOTW98onMrfElOqGXlD0gcWS/4645/bam_files/"
wget $forge_url
# parse into filenames:
myfiles=$( w3m -dump -T text/html index.html | grep -o -E "4645.+bam " )
# mybamindex=$( w3m -dump -T text/html index.html | grep -o -E "4646.+bai" )
# echo $mybamindex
# myfiles2=( "${myfiles[@]}" "${mybamindex[@]}" )
rm index.html*
echo "downloading this many bam files with their index:"
echo $myfiles | wc -w

##### check which files already exist
# echo "enter ssh password"
# read -s password
# export SSHPASS=$password
already_there=$(ssh rhpc ssh begg ls /DATA/users/shared/radplat/DNA/lowcoverage/bam/)
# echo $already_there



# print these to files, to be able to use the comm command later on
printf "%s\n" "$already_there" > already_there.txt
printf "%s\n" "$myfiles" > myfiles.txt

# remove entries common to both locations (-3 option) and files only on the target location (-2 option)
to_download=$(comm -2 -3 myfiles.txt already_there.txt) 
rm already_there.txt
rm myfiles.txt

echo "files to download:"
echo $to_download

# start tunnel if not already running
ssh -f p.essers@rhpc.nki.nl -L 8899:begg:22 -N 8899

for newfile in $to_download
do
	echo $forge_url$newfile
	
	wget $forge_url$newfile
	scp -P 8899 $newfile localhost:$targetdir
	rm $newfile
	
	# also get associated index files
	wget $forge_url$newfile.bai
	scp -P 8899 $newfile.bai localhost:$targetdir
	rm $newfile.bai
done
