const test = require("tape");
const { Ed25519KeyIdentity } = require("@dfinity/identity");
const fs = require("fs");
const path = require("path");
const mime = require("mime");
const { updateChecksum } = require("./utils.cjs");

// Actor Interface
const {
  idlFactory: file_storage_interface,
} = require("../.dfx/local/canisters/file_storage/service.did.test.cjs");

// Canister Ids
const canister_ids = require("../.dfx/local/canister_ids.json");
const file_storage_canister_id = canister_ids.file_storage.local;

// Identities
let motoko_identity = Ed25519KeyIdentity.generate();
let dom_identity = Ed25519KeyIdentity.generate();

const { getActor } = require("./actor.cjs");

let file_storage_actors = {};

let chunk_ids = [];
let chunk_ids_injection = [];
let checksum = 0;

test("Setup Actors", async function (t) {
  console.log("=========== File Storage ===========");

  file_storage_actors.motoko = await getActor(
    file_storage_canister_id,
    file_storage_interface,
    motoko_identity
  );

  file_storage_actors.dom = await getActor(
    file_storage_canister_id,
    file_storage_interface,
    dom_identity
  );
});

test("FileStorage[motoko].version(): should return version number", async function (t) {
  const response = await file_storage_actors.motoko.version();

  t.equal(response, 4n);
});

test("FileStorage[motoko].create_chunk(): with large video file #ok -> chunk_ids", async function (t) {
  const uploadChunk = async ({ chunk, order }) => {
    return file_storage_actors.motoko.create_chunk(chunk, order);
  };

  const file_path = "tests/data/icp.mp4";

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

    checksum = updateChecksum(chunk, checksum);

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

test("FileStorage[dom].commit_batch(): with new identiy #err -> ChunkOwnerInvalid", async function (t) {
  const file_path = "tests/data/bots.mp4";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const { err: error } = await file_storage_actors.dom.commit_batch(chunk_ids, {
    filename: asset_filename,
    checksum: checksum,
    content_encoding: { Identity: null },
    content_type: asset_content_type,
  });

  t.deepEqual(error, { ChunkOwnerInvalid: true });
});

test("FileStorage[motoko].commit_batch(): with invalid chunk #err -> ChunkNotFound", async function (t) {
  const file_path = "tests/data/bots.mp4";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const { ok: asset_id, err: error } =
    await file_storage_actors.motoko.commit_batch([...chunk_ids, 6000000n], {
      filename: asset_filename,
      checksum: checksum,
      content_encoding: { Identity: null },
      content_type: asset_content_type,
    });

  t.deepEqual(error, { ChunkNotFound: true });
});

test("FileStorage[motoko].create_chunk(): with image file for injection #ok -> chunk_ids", async function (t) {
  const uploadChunk = async ({ chunk, order }) => {
    return file_storage_actors.motoko.create_chunk(chunk, order);
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

  chunk_ids_injection = await Promise.all(promises);

  const hasChunkIds = chunk_ids.length > 2;

  t.equal(hasChunkIds, true);
});

test("FileStorage[motoko].commit_batch(): with invalid chunk #err -> ChecksumInvalid", async function (t) {
  const file_path = "tests/data/bots.mp4";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const all_ids = [...chunk_ids, ...chunk_ids_injection].sort((a, b) =>
    a < b ? -1 : a > b ? 1 : 0
  );

  const { ok: asset_id, err: error } =
    await file_storage_actors.motoko.commit_batch(all_ids, {
      filename: asset_filename,
      checksum: checksum,
      content_encoding: { Identity: null },
      content_type: asset_content_type,
    });

  t.deepEqual(error, { ChecksumInvalid: true });
});

test("FileStorage[motoko].commit_batch(): with large video file #ok -> asset_id", async function (t) {
  const file_path = "tests/data/icp.mp4";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);
  const options = {
    filename: asset_filename,
    checksum: checksum,
    content_encoding: { Identity: null },
    content_type: asset_content_type,
  };

  const ids_sorted = chunk_ids.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));

  const { ok: asset_id, err: error } =
    await file_storage_actors.motoko.commit_batch(ids_sorted, options);

  const { ok: asset } = await file_storage_actors.motoko.get(asset_id);

  checksum = 0;

  t.equal(asset.filename, "icp.mp4");
  t.equal(asset.content_type, "video/mp4");
  t.equal(asset.content_size, 39523502n);
});

test("FileStorage[motoko].create_chunk(): with image file #ok -> chunk_ids", async function (t) {
  const uploadChunk = async ({ chunk, order }) => {
    return file_storage_actors.motoko.create_chunk(chunk, order);
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

    checksum = updateChecksum(chunk, checksum);

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

test("FileStorage[motoko].commit_batch(): with image file #ok -> asset_id", async function (t) {
  const file_path = "tests/data/poked_3.jpeg";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const ids_sorted = chunk_ids.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));

  const { ok: asset_id, err: error } =
    await file_storage_actors.motoko.commit_batch(ids_sorted, {
      filename: asset_filename,
      checksum: checksum,
      content_encoding: { Identity: null },
      content_type: asset_content_type,
    });

  checksum = 0;

  const { ok: asset } = await file_storage_actors.motoko.get(asset_id);

  t.equal(asset.filename, "poked_3.jpeg");
  t.equal(asset.content_type, "image/jpeg");
  t.equal(asset.content_size, 8169010n);
});

test("FileStorage[motoko].get_all_assets(): # -> assets", async function (t) {
  const assets = await file_storage_actors.motoko.get_all_assets();

  const hasAssets = assets.length > 1;

  t.equal(hasAssets, true);
});

test("FileStorage[motoko].delete_asset(): with valid asset #ok -> Deleted Asset", async function (t) {
  // Upload an asset
  const file_path = "tests/data/poked_1.jpeg";
  const asset_buffer = fs.readFileSync(file_path);
  const asset_unit8Array = new Uint8Array(asset_buffer);
  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  checksum = updateChecksum(asset_buffer, checksum);

  const chunk_id = await file_storage_actors.motoko.create_chunk(
    asset_unit8Array,
    0
  );
  const { ok: asset_id } = await file_storage_actors.motoko.commit_batch(
    [chunk_id],
    {
      filename: asset_filename,
      checksum: checksum,
      content_encoding: { Identity: null },
      content_type: asset_content_type,
    }
  );

  // Delete the asset
  const { ok: delete_result } = await file_storage_actors.motoko.delete_asset(
    asset_id
  );
  t.equal(delete_result, "Deleted Asset");

  // Check if the asset is no longer in the assets list
  const asset_list = await file_storage_actors.motoko.get_all_assets();
  const deleted_asset = asset_list.find((asset) => asset.id === asset_id);
  t.equal(deleted_asset, undefined);
});

test("FileStorage[motoko].is_full(): should return false when memory usage is below threshold", async function (t) {
  const response = await file_storage_actors.motoko.is_full();

  t.equal(response, false);
});
