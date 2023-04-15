const test = require("tape");
const { Ed25519KeyIdentity } = require("@dfinity/identity");
const fs = require("fs");
const path = require("path");
const mime = require("mime");
const { updateChecksum } = require("./utils.cjs");

// Actor Interface
const {
  idlFactory: file_scaling_manager_interface,
} = require("../.dfx/local/canisters/file_scaling_manager/file_scaling_manager.did.test.cjs");
const {
  idlFactory: file_storage_interface,
} = require("../.dfx/local/canisters/file_storage/file_storage.did.test.cjs");

// Canister Ids
const canister_ids = require("../.dfx/local/canister_ids.json");
const file_scaling_manager_canister_id =
  canister_ids.file_scaling_manager.local;

// Identities
let motoko_identity = Ed25519KeyIdentity.generate();

const { getActor } = require("./actor.cjs");

let file_scaling_manager_actors = {};
let file_storage_actors = {};

let chunk_ids = [];
let batch_id = "";
let checksum = 0;

test("Setup Actors", async function (t) {
  console.log("=========== File Scaling Manager ===========");

  file_scaling_manager_actors.motoko = await getActor(
    file_scaling_manager_canister_id,
    file_scaling_manager_interface,
    motoko_identity
  );
});

test("FileScalingManager[motoko].version(): should return version number", async function (t) {
  const response = await file_scaling_manager_actors.motoko.version();

  t.equal(response, 1n);
});

test("FileScalingManager[motoko].init(): should create file_storage_canister", async function (t) {
  const response = await file_scaling_manager_actors.motoko.init();

  const responded = response.length > 1;

  t.equal(responded, true);
});

test("FileScalingManager[motoko].init(): should return file_storage_canister exists", async function (t) {
  const response = await file_scaling_manager_actors.motoko.init();

  t.equal(response, "file storage canister already exists");
});

test("FileScalingManager[motoko].get_file_storage_canister_id(): should get canister id", async function (t) {
  const canister_id =
    await file_scaling_manager_actors.motoko.get_file_storage_canister_id();

  t.equal(canister_id.length > 1, true);
});

test("Setup Actors", async function (t) {
  console.log("=========== File Storage ===========");

  // Get Canister Id from File Scaling Manager
  const canister_id =
    await file_scaling_manager_actors.motoko.get_file_storage_canister_id();

  // Setup Actor with Canister Id
  file_storage_actors.motoko = await getActor(
    canister_id,
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
  const file_path = "tests/data/bots.mp4";

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

  const { ok: asset } = await file_storage_actors.motoko.get(asset_id);

  t.equal(asset.filename, "bots.mp4");
  t.equal(asset.content_type, "video/mp4");
  t.equal(asset.content_size, 14272571n);
});

test("FileStorage[motoko].assets_list(): should return all assets without file content data since it would be too large", async function (t) {
  const { ok: asset_list } = await file_storage_actors.motoko.assets_list();

  const hasAssets = asset_list.length > 0;

  t.equal(hasAssets, true);
});

test("FileScalingManager[motoko].get_canister_records(): should return all canister records", async function (t) {
  const records =
    await file_scaling_manager_actors.motoko.get_canister_records();

  const hasAssets = records.length > 0;

  t.equal(hasAssets, true);
});
