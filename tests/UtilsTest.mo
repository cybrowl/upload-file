import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import ActorSpec "./ActorSpec";
import Utils "../src/utils";

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
        "get_asset_id()",
        [
            it(
                "should get asset id from local env",
                do {
                    let url = "http://127.0.0.1:8080/asset/b727ade3-32b-ca4-a3f-0555128ec8ce?canisterId=qoctq-giaaa-aaaaa-aaaea-cai";
                    let expected = "b727ade3-32b-ca4-a3f-0555128ec8ce";
                    let asset_id = Utils.get_asset_id(url);

                    assertTrue(Text.equal(asset_id, expected));
                },
            ),
        ],
    ),
    describe(
        "generate_uuid()",
        [
            it(
                "should generate uuid",
                do {
                    let uuid = Utils.generate_uuid();
                    let expected = "4e34f891-9b9-945-ba7-57dcea2a60e4";

                    assertTrue(Text.equal(uuid, expected));
                },
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("Tests failed");
};
