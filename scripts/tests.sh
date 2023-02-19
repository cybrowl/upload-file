#!/bin/bash

npm run gen_can_test_interface

tape tests/file_scaling_manager.test.cjs

tape tests/file_storage.test.cjs