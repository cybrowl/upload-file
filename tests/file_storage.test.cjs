const test = require("tape");
const { Ed25519KeyIdentity } = require("@dfinity/identity");
const fs = require("fs");
const path = require("path");
const mime = require("mime");

// Actor Interface
const {
  idlFactory: file_storage_interface,
} = require("../.dfx/local/canisters/file_storage/file_storage.did.test.cjs");

// Canister Ids
const canister_ids = require("../.dfx/local/canister_ids.json");
const file_storage_canister_id = canister_ids.file_storage.local;

// Identities
let motoko_identity = Ed25519KeyIdentity.generate();

const { getActor } = require("./actor.cjs");

let file_storage_actors = {};

test("Setup Actors", async function (t) {
  console.log("=========== File Storage ===========");

  file_storage_actors.motoko = await getActor(
    file_storage_canister_id,
    file_storage_interface,
    motoko_identity
  );
});

test("FileStorage[motoko].version(): should return version number", async function (t) {
  const response = await file_storage_actors.motoko.version();

  t.equal(response, 1n);
});

test("FileStorage[motoko].create_chunk(): should store chunk data of file to canister", async function (t) {
  const batch_id = Math.random().toString(36).substring(2, 7);

  const uploadChunk = async ({ chunk, order }) => {
    return file_storage_actors.motoko.create_chunk(batch_id, chunk, order);
  };

  const file_path = "tests/data/bots.mp4";

  const asset_buffer = fs.readFileSync(file_path);
  const asset_file_name = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const asset_unit8Array = new Uint8Array(asset_buffer);

  // const file_name = "pod.mp4";

  const promises = [];
  const chunkSize = 2000000;

  for (
    let start = 0, index = 0;
    start < asset_unit8Array.length;
    start += chunkSize, index++
  ) {
    const chunk = asset_unit8Array.slice(start, start + chunkSize);

    promises.push(
      uploadChunk({
        chunk,
        order: index,
      })
    );
  }

  const chunk_ids = await Promise.all(promises);

  console.log("chunk_ids: ", chunk_ids);

  const { ok: asset_id } = await file_storage_actors.motoko.commit_batch(
    batch_id,
    chunk_ids,
    {
      file_name: asset_file_name,
      content_encoding: "gzip",
      content_type: asset_content_type,
    }
  );

  console.log("asset_id: ", asset_id);
  // http://ryjl3-tyaaa-aaaaa-aaaba-cai.localhost:8080/asset/1
  const asset_res = await file_storage_actors.motoko.get(asset_id);

  console.log("asset_res: ", asset_res);

  const size_chunks = await file_storage_actors.motoko.size_chunks();

  console.log("size_chunks: ", size_chunks);

  const hasChunkIds = chunk_ids.length > 2;

  t.equal(hasChunkIds, true);
});

test("FileStorage[motoko].list_assets(): should return all assets without file content data since it would be too large", async function (t) {
  const response = await file_storage_actors.motoko.list_assets();

  console.log("response: ", response);
});
