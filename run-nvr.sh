#!/bin/sh

THISDIR=$(dirname ${BASH_SOURCE[0]})

usage() {
  echo "Usage `basename $0` <package> [ <package> ... ] <nvr> [ <nvr> ... ]"
  exit 1
}

[ $# -lt 1 ] && usage

packages=""
while [ -d "${THISDIR}/packages/$1" ] ; do
  packages="$packages $1"
  shift
done

repodir=$(mktemp -d /var/tmp/db-ci-test-XXXXXX)
pushd "${repodir}"
while [ -n "$1" ] ; do
  koji download-build -a noarch -a x86_64 $1
  shift
done
createrepo_c .
popd

cat >/etc/yum.repos.d/db-ci.repo <<EOF
[db-ci]
name=db-ci
baseurl=file://${repodir}
enabled=0
gpgcheck=0
EOF

[ "$packages" == "" ] && usage

export SKIP_REPO_CREATE=1
"${THISDIR}/run.sh" $packages

