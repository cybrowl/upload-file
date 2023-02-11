const test = require("tape");
const { Ed25519KeyIdentity } = require("@dfinity/identity");

// Actor Interface
const {
  idlFactory: file_scaling_manager_interface,
} = require("../.dfx/local/canisters/file_scaling_manager/file_scaling_manager.did.test.cjs");

// Canister Ids
const canister_ids = require("../.dfx/local/canister_ids.json");
const file_scaling_manager_canister_id =
  canister_ids.file_scaling_manager.local;

// Identities
let motoko_identity = Ed25519KeyIdentity.generate();

const { getActor } = require("./actor.cjs");

let file_scaling_manager_actors = {};

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
