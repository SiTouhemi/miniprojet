#!/bin/bash

echo "Creating test users for login testing..."
echo

cd scripts
node create_test_users.js

echo
echo "Test users creation completed!"
echo "Check test_credentials.txt for login details."
echo