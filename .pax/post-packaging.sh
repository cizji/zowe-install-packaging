#!/bin/sh -e
set -x

################################################################################
# This program and the accompanying materials are made available under the terms of the
# Eclipse Public License v2.0 which accompanies this distribution, and is available at
# https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright IBM Corporation 2019
################################################################################

SCRIPT_NAME=$(basename "$0")
CURR_PWD=$(pwd)
INPUT_TXT=input.txt
ZOWE_VERSION=$(cat version)

if [ -z "${ZOWE_VERSION}" ]; then
  echo "[$SCRIPT_NAME][ERROR] ZOWE_VERSION environment variable is missing"
  exit 1
fi
ZOWE_VERSION_MAJOR=$(echo "${ZOWE_VERSION}" | awk -F. '{print $1}')
# FIXME: what happened if ZOWE_VERSION_MAJOR>10
FMID_VERISON="00${ZOWE_VERSION_MAJOR}"

# create smpe.pax
cd smpe/pax
pax -x os390 -w -f ../../smpe.pax *
cd ../..

# display extracted files
echo "[$SCRIPT_NAME] content of $CURR_PWD...."
find . -print

# find zowe pax
if [ ! -f zowe.pax ]; then
  echo "[$SCRIPT_NAME][ERROR] Cannot find Zowe package."
  exit 1
fi
if [ ! -f smpe.pax ]; then
  echo "[$SCRIPT_NAME][ERROR] Cannot find SMP/e package."
  exit 1
fi

echo "[$SCRIPT_NAME] pareparing ${INPUT_TXT} ..."
echo "${CURR_PWD}/zowe.pax" > "${INPUT_TXT}"
echo "${CURR_PWD}/smpe.pax" >> "${INPUT_TXT}"
echo "[$SCRIPT_NAME] content of ${INPUT_TXT}:"
cat "${INPUT_TXT}"
mkdir -p zowe

./smpe/bld/smpe.sh -i "${CURR_PWD}/${INPUT_TXT}" -v ${FMID_VERISON} -r "${CURR_PWD}/zowe" -d

# get the final build result
ZOWE_SMPE_PAX="AZWE${FMID_VERISON}/gimzip/AZWE${FMID_VERISON}.pax.Z"
if [ ! -f "${CURR_PWD}/zowe/${ZOWE_SMPE_PAX}" ]; then
  echo "[$SCRIPT_NAME][ERROR] cannot find build result ${ZOWE_SMPE_PAX}"
  exit 1
fi
ZOWE_SMPE_README="AZWE${FMID_VERISON}/gimzip/AZWE${FMID_VERISON}.readme.txt"
if [ ! -f "${CURR_PWD}/zowe/${ZOWE_SMPE_README}" ]; then
  echo "[$SCRIPT_NAME][ERROR] cannot find build result ${ZOWE_SMPE_README}"
  exit 1
fi
mv "${CURR_PWD}/zowe/${ZOWE_SMPE_PAX}" "${CURR_PWD}/zowe-smpe.pax"
mv "${CURR_PWD}/zowe/${ZOWE_SMPE_README}" "${CURR_PWD}/readme.txt"

# prepare rename to original name
echo "mv zowe-smpe.pax AZWE${FMID_VERISON}.pax.Z" > "${CURR_PWD}/rename-back.sh.1047"
echo "mv readme.txt AZWE${FMID_VERISON}.readme.txt" >> "${CURR_PWD}/rename-back.sh.1047"
iconv -f IBM-1047 -t ISO8859-1 rename-back.sh.1047 > rename-back.sh
