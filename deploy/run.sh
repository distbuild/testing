#!/usr/bin/env bash

# The contents of this file are covered by APACHE License Version 2.
# See licenses/APACHEV2-LICENSE.txt for more information.
#
# Runs docker-compose files for server and client REAPI implementations

set -eu

HELP="""
./run.sh - A remote-apis-testing wrapper script
  -s [server]: A path to a docker-compose file which will be spun up to represent the server deployment.
  -c [client]: A path to a docker-compose file which will be spun up to represent the client deployment.
  -a [asset server]: A path to a docker-compose file which will be spun up to represent the asset server deployment.
  -d [name]: Dumps the data for this run with a given name. This can be later used in the static site and is of the format {client}+{server}.
  -u [url]: If specified with the -d flag, the provided url is included in the job_url field in the json output.
  -p: Will perform a cleanup of the storage-* directories prior to starting tests. Requires privilege.
  -g: Will generate the docker-compose yaml files, setting the current versions of clients and servers, as defined in matrix.yml
  -G: Same as -g, but will overwrite existing yaml files.
"""

# Initialize optional args
ASSET=""
CLEAN=""
JOB_NAME=""
JOB_URL=""
GENERATE_YAML=""
REGENERATE_YAML=""

while getopts ":s:c:a:d:u:pgG" opt; do
  case ${opt} in
    s ) SERVER="$OPTARG";;
    c ) CLIENT="$OPTARG";;
    a ) ASSET="$OPTARG";;
    d ) JOB_NAME="$OPTARG";;
    u ) JOB_URL="$OPTARG";;
    p ) CLEAN="TRUE";;
    g ) GENERATE_YAML="TRUE";;
    G ) REGENERATE_YAML="TRUE";;
    : ) echo "Missing argument for -$OPTARG" && exit 1;;
    \?) echo "$HELP" && exit 1;;
  esac
done

# Check docker-compose version
dc_version=$(docker-compose version --short)
dc_major=$(echo $dc_version | cut -d "." -f1)
dc_minor=$(echo $dc_version | cut -d "." -f2)
dc_patch=$(echo $dc_version | cut -d "." -f3)
dc_major_target=1
dc_minor_target=25
dc_patch_target=1
if [ $dc_major -lt $dc_major_target ] || \
   [ $dc_major -eq $dc_major_target -a $dc_minor -lt $dc_minor_target ] || \
   [ $dc_major -eq $dc_major_target -a $dc_minor -eq $dc_minor_target -a $dc_patch -lt $dc_patch_target ]; then
    echo "ERROR: docker-compose version must be $dc_major_target.$dc_minor_target.$dc_patch_target or higher. (run 'docker-compose version' to see your current version.)" && false
fi

# Local directory mounted as a volume for the worker
WORKER="worker"

# bb is a directory created by buildbarn deployments and should be removed
# at the start of every buildbarn deployment to prevent ETXTBSY errors from occurring.
# If -p is set this effectively gives a clean environment akin to CI runs.
rm -rf $WORKER bb

mkdir -m 0777 -p $WORKER/{build,cache,remote-execution}

if [[ "$CLEAN" != "" ]]; then
  echo "Performing optional clean" 1>&2
  rm -rf storage-*
fi

if [[ "$GENERATE_YAML" != "" || "$REGENERATE_YAML" != "" ]]; then
  if [[ "$REGENERATE_YAML" != "" ]]; then
    echo "(Re)generating docker-compose yaml files." 1>&2
    REGENERATE_FORCE_ARG="--force"
  else
    echo "Generating docker-compose yaml files." 1>&2
    REGENERATE_FORCE_ARG=""
  fi

  ./build.py -q ${REGENERATE_FORCE_ARG}
fi

cleanup() {
    EXIT_STATUS=$?
    # Removing $SERVER with orphans will ensure all other
    # services deployed afterwards are removed.
    docker-compose -f "$SERVER" down --remove-orphans

    if [[ "$JOB_NAME" != "" ]]; then
      PASS=$([ "$EXIT_STATUS" == 0 ] && echo "true" || echo "false")

      # Add the job url so that the static site can link
      # to the exact job that created a given result
      JOB_URL_ARG=$([ "$JOB_URL" != "" ] && echo ", \"job_url\": \"$JOB_URL\"" || echo "")
      echo "{ \"pass\": $PASS, \"name\": \"$JOB_NAME\"$JOB_URL_ARG }"
    fi

    exit $EXIT_STATUS
}
trap cleanup EXIT

# Enable buildroot for building images via docker-compose
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

docker-compose -f "$SERVER" build 1>&2
docker-compose -f "$SERVER" up -d 1>&2
docker-compose -f "$SERVER" logs --follow 1>&2 &

if [[ "$ASSET" != "" ]]; then
  docker-compose -f "$ASSET" build 1>&2
  docker-compose -f "$ASSET" up -d 1>&2
  docker-compose -f "$ASSET" logs --follow 1>&2 &
fi

docker-compose -f "$CLIENT" build 1>&2
docker-compose -f "$CLIENT" up --exit-code-from client 1>&2
