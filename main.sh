#!/bin/bash

FILENAME=$main.sh
echo	"#!/bin/bash"	>	$FILENAME
chmod +x $FILENAME
vim $FILENAME
