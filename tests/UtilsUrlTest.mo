import Utils "../src/utils";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Array "mo:base/Array";

import ActorSpec "./ActorSpec";
type Group = ActorSpec.Group;

let assertTrue = ActorSpec.assertTrue;
let assertFalse = ActorSpec.assertFalse;
let describe = ActorSpec.describe;
let it = ActorSpec.it;
let skip = ActorSpec.skip;
let pending = ActorSpec.pending;
let run = ActorSpec.run;

let success = run([
    describe(
        "AssetsUtils.get_asset_id()",
        [
            it(
                "should get asset id from local env",
                do {
                    let url = "http://127.0.0.1:8080/asset/10?canisterId=qoctq-giaaa-aaaaa-aaaea-cai";
                    let expected = 10;
                    let asset_id = Utils.get_asset_id(url);
                    assertTrue(Nat.equal(asset_id, expected));
                },
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("Tests failed");
};
