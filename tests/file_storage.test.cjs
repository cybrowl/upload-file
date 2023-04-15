const test = require("tape");
const { Ed25519KeyIdentity } = require("@dfinity/identity");
const fs = require("fs");
const path = require("path");
const mime = require("mime");
const { updateChecksum } = require("./utils.cjs");

// Actor Interface
const {
  idlFactory: file_storage_interface,
} = require("../.dfx/local/canisters/file_storage/file_storage.did.test.cjs");

// Canister Ids
const canister_ids = require("../.dfx/local/canister_ids.json");
const file_storage_canister_id = canister_ids.file_storage.local;

// Identities
let motoko_identity = Ed25519KeyIdentity.generate();
let dom_identity = Ed25519KeyIdentity.generate();

const { getActor } = require("./actor.cjs");

let file_storage_actors = {};

let chunk_ids = [];
let batch_id = "";
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

test("FileStorage[dom].commit_batch(): should return error not authorized since not owner of chunks", async function (t) {
  const file_path = "tests/data/bots.mp4";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const { err: error } = await file_storage_actors.dom.commit_batch(
    batch_id,
    chunk_ids,
    {
      filename: asset_filename,
      checksum: checksum,
      content_encoding: { Identity: null },
      content_type: asset_content_type,
    }
  );

  t.equal(error, "Not Owner of Chunk");
});

test("FileStorage[motoko].commit_batch(): should start formation of asset to be stored", async function (t) {
  const file_path = "tests/data/bots.mp4";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const { ok: asset_id, err: error } =
    await file_storage_actors.motoko.commit_batch(batch_id, chunk_ids, {
      filename: asset_filename,
      checksum: checksum,
      content_encoding: { Identity: null },
      content_type: asset_content_type,
    });

  const { ok: asset } = await file_storage_actors.motoko.get(asset_id);

  t.equal(asset.filename, "bots.mp4");
  t.equal(asset.content_type, "video/mp4");
  t.equal(asset.content_size, 14272571n);
});

test("FileStorage[motoko].commit_batch(): should err => Invalid Checksum", async function (t) {
  const file_path = "tests/data/bots.mp4";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const { ok: asset_id, err: error } =
    await file_storage_actors.motoko.commit_batch(batch_id, chunk_ids, {
      filename: asset_filename,
      checksum: checksum,
      content_encoding: { Identity: null },
      content_type: asset_content_type,
    });

  checksum = 0;

  t.equal(error, "Invalid Checksum: Chunk Missing");
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

test("FileStorage[motoko].commit_batch(): should start formation of asset to be stored", async function (t) {
  const file_path = "tests/data/poked_3.jpeg";

  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);

  const { ok: asset_id } = await file_storage_actors.motoko.commit_batch(
    batch_id,
    chunk_ids,
    {
      filename: asset_filename,
      checksum: checksum,
      content_encoding: { Identity: null },
      content_type: asset_content_type,
    }
  );

  checksum = 0;

  const { ok: asset } = await file_storage_actors.motoko.get(asset_id);

  t.equal(asset.filename, "poked_3.jpeg");
  t.equal(asset.content_type, "image/jpeg");
  t.equal(asset.content_size, 8169010n);
});

test("FileStorage[motoko].assets_list(): should return all assets without file content data since it would be too large", async function (t) {
  const { ok: asset_list } = await file_storage_actors.motoko.assets_list();

  const hasAssets = asset_list.length > 1;

  t.equal(hasAssets, true);
});

test("FileStorage[motoko].delete_asset(): should delete an asset", async function (t) {
  // Upload an asset
  const file_path = "tests/data/poked_1.jpeg";
  const asset_buffer = fs.readFileSync(file_path);
  const asset_unit8Array = new Uint8Array(asset_buffer);
  const asset_filename = path.basename(file_path);
  const asset_content_type = mime.getType(file_path);
  const batch_id = Math.random().toString(36).substring(2, 7);

  checksum = updateChecksum(asset_buffer, checksum);

  const chunk_id = await file_storage_actors.motoko.create_chunk(
    batch_id,
    asset_unit8Array,
    0
  );
  const { ok: asset_id } = await file_storage_actors.motoko.commit_batch(
    batch_id,
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
  t.equal(delete_result, "Asset deleted successfully.");

  // Check if the asset is no longer in the assets list
  const { ok: asset_list } = await file_storage_actors.motoko.assets_list();
  const deleted_asset = asset_list.find((asset) => asset.id === asset_id);
  t.equal(deleted_asset, undefined);
});

test("FileStorage[motoko].start_clear_expired_chunks(): should start clearing chunks cron job", async function (t) {
  const timer_id =
    await file_storage_actors.motoko.start_clear_expired_chunks();

  t.equal(timer_id, 1n);
});

test("FileStorage[motoko].is_full(): should return false when memory usage is below threshold", async function (t) {
  const response = await file_storage_actors.motoko.is_full();

  t.equal(response, false);
});
