#!/bin/bash

# Caution: This is common script that is shared by more packages.
# If you need to do changes related to this particular collection,
# create a copy of this file instead of symlink.

THISDIR=$(dirname ${BASH_SOURCE[0]})
source ${THISDIR}/../../../common/functions.sh
source ${THISDIR}/../include.sh

${THISDIR}/../../mysql-common/parallel-mysql/install_combinations
