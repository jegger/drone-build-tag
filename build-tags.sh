#!/bin/bash

# Override basic drone tags.

#
# Use --py-module to specify the module from which the version should be loaded.
#

function join_by { local IFS="$1"; shift; echo "$*"; }

# Get version from python package
if [ "$1" == --py-module ]; then
  if [ -z "$2" ]; then
    VERSION="$(python3 -c 'import version; print(version.__version__)')"
  else
    PY_MODULE="$2"
    VERSION="$(python3 -c 'import '$PY_MODULE'; print('$PY_MODULE'.__version__)')"
  fi
  if [ $? -ne 0 ]; then
    echo "ERROR: Was not able to get version from python module"
    exit 1
  fi
elif [ -f "./package.json" ]; then
  # Node
  VERSION=$(jq -r .version ./package.json )
  echo "Found package.json"
elif [ -f "./version" ]; then
  # a version file
  VERSION=$(cat ./version)
  echo "Found .version file"
elif [ -f "./pom.xml" ]; then
  # a maven pom file
  VERSION=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" pom.xml )
  echo "Found pom.xml file"
elif [ -f "./Dockerfile" ]; then
  # from APPLICATION_VERSION in Docker file
  VERSION=$(grep 'ENV APPLICATION_VERSION' Dockerfile | awk '{print $3}')
  echo "Found version in Dockerfile file"
else
  echo "ERROR: Can't figure out version"
  exit 1
fi

GIT_BRANCH=$(git symbolic-ref --short HEAD)

echo "VERSION: ${VERSION}"
echo "DRONE_COMMIT_BRANCH: ${DRONE_COMMIT_BRANCH}"
echo "DRONE_BUILD_NUMBER: ${DRONE_BUILD_NUMBER}"
echo "GIT_BRANCH: " ${GIT_BRANCH}
echo "DRONE_COMMIT_SHA: ${DRONE_COMMIT_SHA:0:7}"

if [ "${GIT_BRANCH}" != "master" ]; then
  INCLUDE_FEATURE_TAG="true"
fi

# Count tags since last commit
echo git describe --abbrev=0 --tags
TAG=$(git describe --abbrev=0 --tags)        # Get latest git tag
echo git rev-list $TAG | head -n 1
TAG_COMMIT=$(git rev-list $TAG | head -n 1)  # Get commit of latest tag
echo git rev-list $TAG^..HEAD | wc -l
COUNT=$(git rev-list $TAG^..HEAD | wc -l)    # Count commits since last tag
COUNT=$((COUNT-1))                           # Decrease count by one

echo "Number of commits since last tag" $COUNT


TAGS=()
if [ "${GIT_BRANCH}" == "master" ]; then
  # Check if this commit is tagged
  # Only if we are on master and the commit-tag == found version
  # then release master-style tag (latest; <version>)
  FINAL_TAG=false
  GIT_TAG=$(git describe --tags)
  if [ $? -eq 0 ]; then
    echo $GIT_TAG "==" $VERSION
    if [ $GIT_TAG == $VERSION ]; then
      echo "Writing master style tags"
      TAGS+=("${VERSION}")
      TAGS+=("latest")
      FINAL_TAG=true
    fi
  fi

  # If it is not correctly tagged, create VERSION.
  if [ "$FINAL_TAG" = false ] ; then
    TAGS+=("${VERSION}-${DRONE_COMMIT_SHA:0:7}")
    TAGS+=("latest")
  fi
fi

if [ "${INCLUDE_FEATURE_TAG}" == "true" ]; then
  CONVERTED_BRANCH=${GIT_BRANCH//\//\_}
  echo "Writing feature style tag" $CONVERTED_BRANCH
  TAGS+=("${VERSION}-${CONVERTED_BRANCH}.${DRONE_COMMIT_SHA:0:7}-${DRONE_BUILD_NUMBER}")
fi

echo "Writing tags to .tags file:"
echo " - PLUGIN_TAGS=$(join_by , ${TAGS[*]})"
# echo "PLUGIN_TAGS=$(join_by , ${TAGS[*]})" > .tags
echo "$(join_by , ${TAGS[*]})" >> .tags
