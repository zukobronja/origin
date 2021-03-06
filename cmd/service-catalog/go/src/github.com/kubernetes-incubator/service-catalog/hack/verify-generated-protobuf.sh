#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

APIROOTS=${APIROOTS:-pkg}
_tmp="${OS_ROOT}/_output/diff"

cleanup() {
  echo rm -rf "${_tmp}"
}

trap "cleanup" EXIT SIGINT

cleanup
for APIROOT in ${APIROOTS}; do
  mkdir -p "${_tmp}/${APIROOT%/*}"
  cp -rf "${OS_ROOT}/${APIROOT}" "${_tmp}/"
done

"${OS_ROOT}/hack/update-generated-protobuf.sh"
for APIROOT in ${APIROOTS}; do
  TMP_APIROOT="${_tmp}/${APIROOT}"
  echo "diffing ${APIROOT} against freshly generated protobuf"
  ret=0
  diff -Naupr -I 'Auto generated by' "${OS_ROOT}/${APIROOT}" "${TMP_APIROOT}" || ret=$?
  # cp -rf "${TMP_APIROOT}" "${OS_ROOT}/${APIROOT%/*}"
  if [[ $ret -eq 0 ]]; then
    echo "${APIROOT} up to date."
  else
    echo "${APIROOT} is out of date. Please run hack/update-generated-protobuf.sh"
    exit 1
  fi
done
