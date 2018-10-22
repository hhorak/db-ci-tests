#!/bin/bash

THISDIR=$(dirname ${BASH_SOURCE[0]})

if [ $# -lt 1 ] ; then
  echo "Usage: `basename $0` <package> [ <package> ]"
  exit 1
fi

test_dir=$(mktemp -d "/var/tmp/test-db-XXXXXX")


mkdir ${test_dir}/db-ci-tests
tar cfz ${test_dir}/db-ci-tests/db-ci-tests.tar.gz \
    "$(readlink -f $(dirname $(readlink -f ${BASH_SOURCE[0]}))/..)"

cat >${test_dir}/run1minutetip.sh <<EOF
PACKAGES="koji createrepo git wget vim"
1minutetip -p "PACKAGES=\"\${PACKAGES}\"" 1MT-Fedora24
EOF

cat >${test_dir}/runtest.sh <<EOF
#!/bin/bash
set -x
echo PASS >/tmp/1minutetip.result

dnf -y install koji createrepo wget vim

pushd db-ci-tests
tar xfz db-ci-tests.tar.gz
popd

EOF

while [ -n "$1" ] ; do
  cat >>${test_dir}/runtest.sh <<EOF
pushd "db-ci-tests/packages/$1"
./run.sh
popd
EOF
  shift
done

chmod a+x ${test_dir}/run*sh
cp ${THISDIR}/Makefile ${test_dir}/

echo "Test ready at ${test_dir} . To run it:"
eval "pushd ${test_dir} ; ./run1minutetip.sh ; popd"
