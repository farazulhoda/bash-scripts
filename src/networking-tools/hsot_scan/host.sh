#!/bin/bash

clear
read -p "Enter a host: " HOST

host=($HOST)
num_subdomains=$(cat subDomain2.txt | wc -1)

for hosts in "{host[@]}"
do
	curl --silent --insecure "https://sonar.omnisint.io/subdomains/$HOST" > subdomains1.txt
	cat subdomains1.txt | grep -oE "[a-zA-Z0-9._-]+\.$HOST" | sort -u > subdomains2.txt
	
	echo "were found: $num_subdomains subdomains"

done
