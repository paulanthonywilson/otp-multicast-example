#! /usr/bin/env sh

set -e

cd `dirname $0`/..

docker build -t multicast .
docker run -it multicast iex -S mix
