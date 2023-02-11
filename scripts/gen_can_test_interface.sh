#!/bin/bash

# TESTING #
# NOTE: update file OSX ONLY (Linux remove '')

# file_scaling_manager
cp .dfx/local/canisters/file_scaling_manager/file_scaling_manager.did.js .dfx/local/canisters/file_scaling_manager/file_scaling_manager.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/file_scaling_manager/file_scaling_manager.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/file_scaling_manager/file_scaling_manager.did.test.cjs

# file_storage
cp .dfx/local/canisters/file_storage/file_storage.did.js .dfx/local/canisters/file_storage/file_storage.did.test.cjs
sed -i '' 's/export//g' .dfx/local/canisters/file_storage/file_storage.did.test.cjs
echo "module.exports = { idlFactory };" >> .dfx/local/canisters/file_storage/file_storage.did.test.cjs