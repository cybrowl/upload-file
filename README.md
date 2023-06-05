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

`vessel sources`

`dfx deploy file_scaling_manager`

`dfx deploy file_storage`

## Important

use node 18x

## Testing

`npm run test`

# FileStorage Actor

The `FileStorage` actor is an Internet Computer canister for storing, retrieving, and managing files. The actor provides a simple interface to handle file storage in chunks, making it easier to work with large files.

## Features

- Store files by uploading them in chunks
- Commit chunks to create a complete file
- List, retrieve, and delete files
- Check the storage capacity

## Interface

The `FileStorage` actor provides the following public methods:

- `create_chunk(batch_id: Chunk_ID, chunk: Blob, order: Nat)`: Store a chunk of a file with a given batch ID and order.
- `commit_batch(batch_id: Chunk_ID, chunk_ids: [Chunk_ID], metadata: Metadata)`: Commit all batch operations to the asset canister, creating a complete file from the chunks.
- `delete_chunk(chunk_id: Chunk_ID)`: Delete a specific chunk from the storage.
- `delete_asset(asset_id: Asset_ID)`: Delete a specific asset from the storage.
- `clear_expired_chunks()`: Clear all expired chunks from the storage.
- `assets_list()`: Retrieve a list of all files in the asset canister.
- `get(asset_id: Asset_ID)`: Retrieve a specific file from the asset canister.
- `chunks_size()`: Retrieve the total size of all chunks in the file storage canister.
- `version()`: Retrieve the version information of the assets canister.
- `is_full()`: Check if the storage capacity has reached its threshold.

## Usage

To interact with the `FileStorage` actor, deploy it to the Internet Computer and use the JavaScript interface (e.g., `AssetManager` class) provided in the same repository. The JavaScript interface simplifies the interaction with the actor, making it easier to use.

You can find example usage of the `AssetManager` class in the README file for the JavaScript interface.

# FileScalingManager Actor

The FileScalingManager actor is an Internet Computer canister that manages multiple FileStorage canisters, dynamically creating new ones when the current canister is full. This enables a scalable solution for file storage on the Internet Computer.

## Features

- Automatically create new FileStorage canisters when needed
- Retrieve the ID of the current FileStorage canister
- View canister records

## Interface

The FileScalingManager actor provides the following public methods:

- `get_file_storage_canister_id()`: Retrieve the ID of the current FileStorage canister. If the current canister is full, a new one will be created.
- `get_canister_records()`: Retrieve a list of all managed FileStorage canisters with their information.
- `init()`: Initialize the FileScalingManager by creating a new FileStorage canister if none exists.
- `version(`): Retrieve the version information of the FileScalingManager actor.

## Usage

To interact with the FileScalingManager actor, deploy it to the Internet Computer. Use the provided public methods to manage FileStorage canisters, which in turn handle file storage.

In your application, you can communicate with the FileScalingManager actor to get the current FileStorage canister ID and use it to interact with the FileStorage actor (e.g., using the AssetManager class from the FileStorage README).

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
