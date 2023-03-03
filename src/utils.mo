import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import Debug "mo:base/Debug";

module {
    private type GenerateAssetUrlArgs = {
        asset_id : Text;
        canister_id : Text;
        is_prod : Bool;
    };

    public func get_asset_id(url : Text) : Nat {
        let urlSplitByPath : [Text] = Iter.toArray(Text.tokens(url, #char '/'));
        let lastElem : Text = urlSplitByPath[urlSplitByPath.size() - 1];
        let filterByQueryString : [Text] = Iter.toArray(Text.tokens(lastElem, #char '?'));

        return Option.get(Nat.fromText(filterByQueryString[0]), 0);
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
};
