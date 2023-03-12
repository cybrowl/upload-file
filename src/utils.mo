import { Buffer; toArray } "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Nat32 "mo:base/Nat32";

module {
    private type GenerateAssetUrlArgs = {
        asset_id : Text;
        canister_id : Text;
        is_prod : Bool;
    };

    public func get_asset_id(url : Text) : Text {
        let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(url, #char '/'));
        let lastElem : Text = urlSplitByPath[urlSplitByPath.size() - 1];
        let filterByQueryString : [Text] = Iter.toArray(Text.tokens(lastElem, #char '?'));

        return filterByQueryString[0];
    };

    public func generate_asset_url(args : GenerateAssetUrlArgs) : Text {
        var url = Text.join(
            "",
            (["https://", args.canister_id, ".raw.ic0.app", "/asset/", args.asset_id].vals()),
        );

        if (args.is_prod == false) {
            url := Text.join(
                "",
                (["http://", args.canister_id, ".localhost:8080/asset/", args.asset_id].vals()),
            );
        };

        return url;
    };

    public func random_from_time() : [Nat] {
        let seed = Time.now();

        var randomness = Buffer<Nat>(0);

        let one = Nat32.toNat(Hash.hash(Int.abs(Time.now())));

        for (i in Iter.range(0, 32)) {
            if (i == 0) {
                randomness.add(one);
            } else {
                let prev = randomness.get(i - 1);
                let next = Nat32.toNat(Hash.hash(prev));
                randomness.add(next);
            };
        };

        return toArray(randomness);
    };

    public func generate_uuid() : Text {
        let hex_chars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
        var uuid = Buffer<Char>(0);

        let randomness = random_from_time();

        for (i in Iter.range(0, 32)) {
            if (i == 8 or i == 12 or i == 16 or i == 20) {
                uuid.add('-');
            } else {
                uuid.add(hex_chars[randomness[i] % 16]);
            };
        };

        let uuid_arr = toArray(uuid);

        return Text.fromIter(uuid_arr.vals());
    };
};
