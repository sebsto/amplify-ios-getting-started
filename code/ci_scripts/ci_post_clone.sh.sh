#!/bin/sh

#  ci_post_clone.sh.sh
#  getting started
#
#  Created by Stormacq, Sebastien on 16/09/2022.
#  Copyright © 2022 Stormacq, Sebastien. All rights reserved.

uname -a
ls -al /
cat /etc/motd
ps -ax

echo "ci_post_clone - done"
exit 0
