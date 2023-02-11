const test = require("tape");
const { Ed25519KeyIdentity } = require("@dfinity/identity");

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
