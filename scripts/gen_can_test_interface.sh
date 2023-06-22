#!/bin/bash

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

# file_scaling_manager
cp .dfx/local/canisters/file_scaling_manager/service.did.js .dfx/local/canisters/file_scaling_manager/service.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/file_scaling_manager/service.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/file_scaling_manager/service.did.test.cjs

# file_storage
cp .dfx/local/canisters/file_storage/service.did.js .dfx/local/canisters/file_storage/service.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/file_storage/service.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/file_storage/service.did.test.cjs