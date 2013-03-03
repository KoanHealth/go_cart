#!/bin/bash
set -e
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/../"
pushd $PROJECT_DIR

gem build go_cart.gemspec
for f in *.gem; do gem install --local $f; done
rm -rf *.gem

popd