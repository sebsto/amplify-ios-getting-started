#!/bin/sh

#  ci_post_clone.sh.sh
#  getting started
#
#  Created by Stormacq, Sebastien on 16/09/2022.
#  Copyright © 2022 Stormacq, Sebastien. All rights reserved.

echo "---------------------------------------------------------"
uname -a
echo "---------------------------------------------------------"
ls -al /
echo "---------------------------------------------------------"
cat /etc/motd
echo "---------------------------------------------------------"
ps -ax
echo "---------------------------------------------------------"
echo $HOME
echo "---------------------------------------------------------"

echo "ci_post_clone - done"
exit 0