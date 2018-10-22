# Some common functions for scripts in this directory

# removes comments and empty lines from a file
strip_comments() {
  cat | sed -e 's:#.*$::g' -e '/^[[:space:]]*$/d'
}

# get major version of the system
os_major_version() {
  [ -n "$OVERRIDE_OS_MAJOR_VERSION" ] && echo $OVERRIDE_OS_MAJOR_VERSION && return
  rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release) | grep -o "^[0-9]*"
}

get_repo_name() {
  echo "db-ci-test-${1}-${2}"
}

get_all_packages_in_repo() {
  packagename="${1}"
  repotype=${REPOTYPE-updates-testing-pending}
  el_version="${2-`os_major_version`}"
  repo_name_default=$(get_repo_name "${el_version}" "${repotype}")
  repo_name=${REPONAME-$repo_name_default}
  # in case such repo does not exist, use all packages with that $PACKAGE prefix
  if ! grep -e "^\[${repo_name}\]$" /etc/yum.repos.d/*.repo &>/dev/null ; then
    echo "${PACKAGE}-*"
    return
  fi
  if [ `os_major_version` -gt 7 ] ; then
    dnf repoquery --disablerepo=\* --enablerepo=${repo_name} -q --arch=x86_64
  else
    repoquery --disablerepo=\* --enablerepo=${repo_name} -q -a --arch=x86_64
  fi
}

# generate a dnf repo file for downloaded data and write it to stdout
# accepts these possitional arguments:
# * package name
# * el_version (24, 25, ...), optional
# The following environment variables can be set to change default values:
# * REPOTYPE, if not set, then updates-testing-pending
# * REPOFILE, if not set, then db-ci.repo
# * SKIP_REPO_CREATE, if set to 1, then no repository is created
generate_repo() {
  [ "0$SKIP_REPO_CREATE" -eq 1 ] && return
  repotype=${REPOTYPE-updates-testing-pending}
  packagename="${1}"
  el_version="${2-`os_major_version`}"
  repo_name=$(get_repo_name "${el_version}" "${repotype}")
  if [ "$repotype" == "mirror" ] ; then
    dnf -y install fedora-repos-${el_version}
  else
    repofile=/etc/yum.repos.d/${REPOFILE-db-ci.repo}
    repodir=/var/tmp/db-ci-test-repo
    tag="f${el_version}-${repotype}"
    rm -rf "${repodir}"
    mkdir "${repodir}"
    pushd "${repodir}" &>/dev/null
    nvr=$(koji latest-build --quiet "${tag}" "${packagename}" | awk '{print $1}')
    koji download-build --arch=x86_64 --arch=noarch ${nvr}
    createrepo .
    popd &>/dev/null
    rm -f "$repofile" ; touch "$repofile"
    cat >> "$repofile" <<- EOM
[${repo_name}]
name=${repo_name}
baseurl=file://${repodir}
gpgcheck=0
enabled=1

EOM
    dnf clean all --disablerepo=\* --enablerepo=${repo_name}
  fi
}

project_root() {
  readlink -f $(dirname `dirname ${BASH_SOURCE[0]}`)
}

exit_fail() {
  echo -n "[FAIL] "
  echo $@
  exit 1
}

# install basic tools that are usually needed for building other SW
install_build_tools() {
  dnf -y install \
      bash bzip2 coreutils cpio diffutils findutils gawk gcc gcc-c++ grep \
      gzip info make patch redhat-rpm-config rpm-build sed shadow-utils \
      tar unzip util-linux-ng wget which iso-codes
}

