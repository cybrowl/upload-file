# File Upload

This code is a tutorial on best practices in response to Bounty 45 from ICDevs.

## Problem

Uploading large files to the IC has been a challenge due to its 2MB ingress limit. To overcome this issue, you need a custom integration that breaks the file into 2MB chunks and handles the sequential uploading process by calling the IC repeatedly. This will ensure the file can be uploaded successfully to your canister.

## Solution

We believe that fast uploading speed, secure data integrity, and secure authentication are essential requirements for this bounty. Fast uploading speed will ensure that the process is efficient and user-friendly, reducing the amount of time users have to wait for their files to be uploaded. Secure data integrity will guarantee that the files are protected and remain unchanged during and after the upload process. Secure authentication will protect sensitive information and ensure that only authorized users have access to the uploaded files.

It's crucial to take scalability into consideration in this bounty. The system should have the capability to accommodate a substantial number of users and files without sacrificing its performance or stability. This will broaden the system's usability and suit a wider array of users and applications.

Furthermore, the capability to visualize the file chunking process in various front-end frameworks is also significant. This function will give users insight into how their files are being uploaded and processed, making it easier for them to integrate the code.

## Getting Started

`npm i`

`dfx deploy file_scaling_manager`

`dfx deploy file_storage`

## Testing

`npm run test-fs`

or

//TODO: script for setup
