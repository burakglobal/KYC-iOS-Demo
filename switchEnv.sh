#!/bin/sh

case "$1" in
production)
	DEFINES="#define ENV_PROD 1"
	;;
testing)
	DEFINES="#define ENV_TEST 1"
	;;
*)
	echo "Usage: $0 {production|testing}"
	exit 1
esac

if [ -z "${SRCROOT}" ]; then 
	SRCROOT="."
fi

ENV_FILE="${SRCROOT}/Env"

echo "// Please, do not touch me directly. Use switchEnv.sh instead." > "${ENV_FILE}"
echo "${DEFINES}" >> "${ENV_FILE}"

echo "${ENV_FILE}: switched to $1"
