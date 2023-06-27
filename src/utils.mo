import { Buffer; toArray } "mo:base/Buffer";
import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Map "mo:hashmap/Map";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Prim "mo:⛔";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./types";

module {
    type ChunkInfo = Types.ChunkInfo;

    private type GenerateAssetUrlArgs = {
        asset_id : Text;
        canister_id : Text;
        is_prod : Bool;
    };

    let { hashNat } = Map;

    public func get_asset_id(url : Text) : Text {
        let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(url, #char '/'));
        let lastElem : Text = urlSplitByPath[urlSplitByPath.size() - 1];
        let filterByQueryString : [Text] = Iter.toArray(Text.tokens(lastElem, #char '?'));

        return filterByQueryString[0];
    };

    public func generate_asset_url(args : GenerateAssetUrlArgs) : Text {
        var url = Text.join(
            "",
            (["https://", args.canister_id, ".raw.icp0.io", "/asset/", args.asset_id].vals()),
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
        var randomness = Buffer<Nat>(0);

        let hash : Nat32 = hashNat(Int.abs(Time.now()));

        let seed = Nat32.toNat(hash);

        for (i in Iter.range(0, 32)) {
            if (i == 0) {
                randomness.add(seed);
            } else {
                let prev = randomness.get(i - 1);
                let hash_prev : Nat32 = hashNat(prev);

                let next = Nat32.toNat(hash_prev);
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

    public func get_memory_in_mb() : Int {
        let rts_memory_size : Nat = Prim.rts_memory_size();
        let mem_size : Float = Float.fromInt(rts_memory_size);
        let memory_in_megabytes = Float.toInt(Float.abs(mem_size / 1_048_576));

        return memory_in_megabytes;
    };

    public func get_heap_in_mb() : Int {
        let rts_heap_size : Nat = Prim.rts_heap_size();
        let heap_size : Float = Float.fromInt(rts_heap_size);
        let heap_in_megabytes = Float.toInt(Float.abs(heap_size / 1_048_576));

        return heap_in_megabytes;
    };

    public func get_cycles_balance() : Int {
        return ExperimentalCycles.balance();
    };

    public func compare(a : ChunkInfo, b : ChunkInfo) : Order.Order {
        if (a.order < b.order) {
            return #less;
        };
        if (a.order > b.order) {
            return #greater;
        };
        return #equal;
    };
};
