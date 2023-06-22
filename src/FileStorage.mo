import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Map "mo:hashmap/Map";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import { ofBlob } "./CRC32";

import Types "./types";

import Utils "./utils";

actor class FileStorage() = this {
	type Asset = Types.Asset;
	type Asset_ID = Types.Asset_ID;
	type AssetChunk = Types.AssetChunk;
	type AssetProperties = Types.AssetProperties;
	type Chunk_ID = Types.Chunk_ID;

	let ACTOR_NAME : Text = "FileStorage";
	let VERSION : Nat = 1;
	stable var timer_id : Nat = 0;

	// change me when in production
	let IS_PROD : Bool = false;

	let { nhash; thash } = Map;

	private var assets = Map.new<Asset_ID, Asset>(thash);
	private var chunks = Map.new<Chunk_ID, AssetChunk>(nhash);

	stable var assets_stable_storage : [(Asset_ID, Asset)] = [];

	private var chunk_id_count : Chunk_ID = 0;

	private func compare(a : AssetChunk, b : AssetChunk) : Order.Order {
		if (a.order < b.order) {
			return #less;
		};

		if (a.order > b.order) {
			return #greater;
		};

		return #equal;
	};

	public shared ({ caller }) func create_chunk(batch_id : Text, content : Blob, order : Nat) : async Nat {
		chunk_id_count := chunk_id_count + 1;

		let checksum = ofBlob(content);

		let asset_chunk : AssetChunk = {
			batch_id = batch_id;
			checksum = checksum;
			content = content;
			created = Time.now();
			filename = "";
			id = chunk_id_count;
			order = order;
			owner = caller;
		};

		ignore Map.put(chunks, nhash, chunk_id_count, asset_chunk);

		return chunk_id_count;
	};

	public shared ({ caller }) func commit_batch(batch_id : Text, asset_properties : AssetProperties) : async Result.Result<Asset_ID, Text> {
		let ASSET_ID = Utils.generate_uuid();
		let CANISTER_ID = Principal.toText(Principal.fromActor(this));

		var chunks_to_commit = Buffer.Buffer<AssetChunk>(0);
		var asset_content = Buffer.Buffer<Blob>(0);
		var content_size = 0;
		var asset_checksum : Nat32 = 0;
		let modulo_value : Nat32 = 400_000_000;

		for (chunk in Map.vals(chunks)) {
			if (chunk.batch_id == batch_id) {
				if (chunk.owner != caller) {
					return #err("Not Owner of Chunk");
				};

				chunks_to_commit.add(chunk);
			};
		};

		chunks_to_commit.sort(compare);

		for (chunk in chunks_to_commit.vals()) {
			asset_content.add(chunk.content);

			asset_checksum := (asset_checksum + chunk.checksum) % modulo_value;

			content_size := content_size + chunk.content.size();
		};

		if (Nat32.notEqual(asset_checksum, asset_properties.checksum)) {
			return #err("Invalid Checksum: Chunk Missing");
		};

		for (chunk in chunks_to_commit.vals()) {
			Map.delete(chunks, nhash, chunk.id);
		};

		let asset : Types.Asset = {
			canister_id = CANISTER_ID;
			chunks_size = asset_content.size();
			content = Option.make(Buffer.toArray(asset_content));
			content_encoding = asset_properties.content_encoding;
			content_size = content_size;
			content_type = asset_properties.content_type;
			created = Time.now();
			filename = asset_properties.filename;
			id = ASSET_ID;
			url = Utils.generate_asset_url({
				asset_id = ASSET_ID;
				canister_id = CANISTER_ID;
				is_prod = IS_PROD;
			});
			owner = Principal.toText(caller);
		};

		ignore Map.put(assets, thash, ASSET_ID, asset);

		return #ok(asset.id);
	};

	public shared ({ caller }) func delete_asset(id : Asset_ID) : async Result.Result<Text, Text> {
		switch (Map.get(assets, thash, id)) {
			case (?asset) {
				if (asset.owner == Principal.toText(caller)) {
					Map.delete(assets, thash, id);

					return #ok("Asset deleted successfully.");
				} else {
					return #err("Permission denied: You are not the owner of this asset.");
				};
			};
			case (_) {
				return #err("Asset not found.");
			};
		};
	};

	func clear_expired_chunks() : async () {
		let currentTime = Time.now();
		let fiveMinutes = 5 * 60 * 1000000000; // Convert 5 minutes to nanoseconds

		let filteredChunks = Map.mapFilter<Chunk_ID, AssetChunk, AssetChunk>(
			chunks,
			nhash,
			func(key : Chunk_ID, assetChunk : AssetChunk) : ?AssetChunk {
				let age = currentTime - assetChunk.created;
				if (age <= fiveMinutes) {
					return ?assetChunk;
				} else {
					return null;
				};
			},
		);

		chunks := filteredChunks;
	};

	public query func assets_list() : async Result.Result<[Asset], Text> {
		var assets_list = Buffer.Buffer<Asset>(0);

		for (asset in Map.vals(assets)) {
			let asset_without_content : Asset = {
				asset with content = null;
			};

			assets_list.add(asset_without_content);
		};

		return #ok(Buffer.toArray(assets_list));
	};

	public query func get(id : Asset_ID) : async Result.Result<Asset, Text> {
		switch (Map.get(assets, thash, id)) {
			case (?asset) {
				let asset_without_content : Asset = {
					asset with content = null;
				};

				return #ok(asset_without_content);
			};
			case (_) {
				return #err("Asset Not Found");
			};
		};
	};

	public query func chunks_size() : async Nat {
		return Map.size(chunks);
	};

	public query func is_full() : async Bool {
		let MAX_SIZE_THRESHOLD_MB : Float = 1500;

		let rts_memory_size : Nat = Prim.rts_memory_size();
		let mem_size : Float = Float.fromInt(rts_memory_size);
		let memory_in_megabytes = Float.abs(mem_size * 0.000001);

		if (memory_in_megabytes > MAX_SIZE_THRESHOLD_MB) {
			return true;
		} else {
			return false;
		};
	};

	// ------------------------- Get Asset HTTP -------------------------
	public shared query ({ caller }) func http_request(request : Types.HttpRequest) : async Types.HttpResponse {
		let NOT_FOUND : [Nat8] = Blob.toArray(Text.encodeUtf8("Asset Not Found"));

		let asset_id = Utils.get_asset_id(request.url);

		switch (Map.get(assets, thash, asset_id)) {
			case (?asset) {
				let filename = Text.concat("attachment; filename=", asset.filename);

				return {
					body = Blob.toArray(Option.get(asset.content, [])[0]);
					headers = [
						("Content-Type", asset.content_type),
						("accept-ranges", "bytes"),
						("Content-Disposition", filename),
						("cache-control", "private, max-age=0"),
					];
					status_code = 200;
					streaming_strategy = create_strategy({
						asset_id = asset_id;
						chunk_index = 0;
						data_chunks_size = asset.chunks_size;
					});
				};
			};
			case _ {
				return {
					body = NOT_FOUND;
					headers = [];
					status_code = 404;
					streaming_strategy = null;
				};
			};
		};
	};

	private func create_strategy(args : Types.CreateStrategyArgs) : ?Types.StreamingStrategy {
		switch (create_token(args)) {
			case (null) { null };
			case (?token) {
				let self = Principal.fromActor(this);
				let canister_id : Text = Principal.toText(self);
				let canister = actor (canister_id) : actor {
					http_request_streaming_callback : shared () -> async ();
				};

				return ? #Callback({
					token;
					callback = canister.http_request_streaming_callback;
				});
			};
		};
	};

	private func create_token(args : Types.CreateStrategyArgs) : ?Types.StreamingCallbackToken {
		if (args.chunk_index + 1 >= args.data_chunks_size) {
			return null;
		} else {
			let token = {
				asset_id = args.asset_id;
				chunk_index = args.chunk_index + 1;
				content_encoding = "gzip";
			};

			return ?token;
		};
	};

	public shared query ({ caller }) func http_request_streaming_callback(
		st : Types.StreamingCallbackToken
	) : async Types.StreamingCallbackHttpResponse {
		switch (Map.get(assets, thash, st.asset_id)) {
			case (null) throw Error.reject("asset_id not found: " # st.asset_id);
			case (?asset) {
				return {
					token = create_token({
						asset_id = st.asset_id;
						chunk_index = st.chunk_index;
						data_chunks_size = asset.chunks_size;
					});
					body = Option.get(asset.content, [])[st.chunk_index];
				};
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	public func start_clear_expired_chunks() : async Timer.TimerId {
		if (timer_id == 0) {
			timer_id := 1;

			return Timer.recurringTimer(#seconds(300), clear_expired_chunks);
		} else {
			return timer_id;
		};
	};

	public func stop_clear_expired_chunks() : async Timer.TimerId {
		timer_id := 0;

		Timer.cancelTimer(1);

		return 0;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		assets_stable_storage := Iter.toArray(Map.entries(assets));
	};

	system func postupgrade() {
		assets := Map.fromIter<Asset_ID, Asset>(assets_stable_storage.vals(), thash);

		assets_stable_storage := [];
	};
};
