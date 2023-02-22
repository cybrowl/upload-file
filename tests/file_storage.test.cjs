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

let chunk_ids = [];
let batch_id = "";

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

test("FileStorage[motoko].create_chunk(): should store chunk data of video file to canister", async function (t) {
  batch_id = Math.random().toString(36).substring(2, 7);

  const uploadChunk = async ({ chunk, order }) => {
    return file_storage_actors.motoko.create_chunk(batch_id, chunk, order);
  };

  const file_path = "tests/data/bots.mp4";

  const asset_buffer = fs.readFileSync(file_path);
  const asset_unit8Array = new Uint8Array(asset_buffer);

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

  chunk_ids = await Promise.all(promises);

  const hasChunkIds = chunk_ids.length > 2;

  t.equal(hasChunkIds, true);
});

test("FileStorage[motoko].commit_batch(): should start formation of asset to be stored", async function (t) {
  const file_path = "tests/data/bots.mp4";

  const asset_file_name = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const { ok: asset_id } = await file_storage_actors.motoko.commit_batch(
    batch_id,
    chunk_ids,
    {
      file_name: asset_file_name,
      content_encoding: "gzip",
      content_type: asset_content_type,
    }
  );

  const { ok: asset } = await file_storage_actors.motoko.get(asset_id);

  t.equal(asset.file_name, "bots.mp4");
  t.equal(asset.content_type, "video/mp4");
  t.equal(asset.content_size, 14272571n);

  const size_chunks = await file_storage_actors.motoko.size_chunks();

  t.equal(size_chunks, 0n);
});

test("FileStorage[motoko].create_chunk(): should store chunk data of image file to canister", async function (t) {
  batch_id = Math.random().toString(36).substring(2, 7);

  const uploadChunk = async ({ chunk, order }) => {
    return file_storage_actors.motoko.create_chunk(batch_id, chunk, order);
  };

  const file_path = "tests/data/poked_3.jpeg";

  const asset_buffer = fs.readFileSync(file_path);
  const asset_unit8Array = new Uint8Array(asset_buffer);

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

  chunk_ids = await Promise.all(promises);

  const hasChunkIds = chunk_ids.length > 2;

  t.equal(hasChunkIds, true);
});

test("FileStorage[motoko].commit_batch(): should start formation of asset to be stored", async function (t) {
  const file_path = "tests/data/poked_3.jpeg";

  const asset_file_name = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const { ok: asset_id } = await file_storage_actors.motoko.commit_batch(
    batch_id,
    chunk_ids,
    {
      file_name: asset_file_name,
      content_encoding: "gzip",
      content_type: asset_content_type,
    }
  );

  const { ok: asset } = await file_storage_actors.motoko.get(asset_id);

  t.equal(asset.file_name, "poked_3.jpeg");
  t.equal(asset.content_type, "image/jpeg");
  t.equal(asset.content_size, 8169010n);

  const size_chunks = await file_storage_actors.motoko.size_chunks();

  t.equal(size_chunks, 0n);
});

test("FileStorage[motoko].list_assets(): should return all assets without file content data since it would be too large", async function (t) {
  const { ok: asset_list } = await file_storage_actors.motoko.list_assets();
  const hasAssets = asset_list.length > 2;

  t.equal(hasAssets, true);
});
