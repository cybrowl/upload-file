import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Map "mo:hashmap/Map";
import Nat "mo:base/Nat";
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

actor class FileStorage(is_prod : Bool) = this {
	type Asset = Types.Asset;
	type Asset_ID = Types.Asset_ID;
	type AssetChunk = Types.AssetChunk;
	type AssetProperties = Types.AssetProperties;
	type Chunk_ID = Types.Chunk_ID;
	type Health = Types.Health;

	let ACTOR_NAME : Text = "FileStorage";
	let VERSION : Nat = 4;
	stable var timer_id : Nat = 0;

	let { nhash; thash } = Map;

	private var assets = Map.new<Asset_ID, Asset>(thash);
	private var chunks = Map.new<Chunk_ID, AssetChunk>(nhash);

	stable var assets_stable_storage : [(Asset_ID, Asset)] = [];

	private var chunk_id_count : Chunk_ID = 0;

	public shared ({ caller }) func create_chunk(content : Blob, order : Nat) : async Nat {
		chunk_id_count := chunk_id_count + 1;

		let checksum = Nat32.toNat(ofBlob(content));

		let asset_chunk : AssetChunk = {
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

	public shared ({ caller }) func commit_batch(chunk_ids : [Nat], asset_properties : AssetProperties) : async Result.Result<Asset_ID, Text> {
		let ASSET_ID = Utils.generate_uuid();
		let CANISTER_ID = Principal.toText(Principal.fromActor(this));

		var asset_content = Buffer.Buffer<Blob>(0);
		var content_size = 0;
		var asset_checksum : Nat = 0;
		let modulo_value : Nat = 400_000_000;

		for (id in chunk_ids.vals()) {
			switch (Map.get(chunks, nhash, id)) {
				case (?chunk) {
					if (chunk.owner != caller) {
						return #err("Not Owner of Chunk");
					} else {
						asset_content.add(chunk.content);

						asset_checksum := (asset_checksum + chunk.checksum) % modulo_value;

						content_size := content_size + chunk.content.size();
					};

				};
				case (_) {
					return #err("Chunk Not Found");
				};
			};

		};

		if (Nat.notEqual(asset_checksum, asset_properties.checksum)) {
			return #err("Invalid Checksum");
		};

		for (id in chunk_ids.vals()) {
			Map.delete(chunks, nhash, id);
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
				is_prod = is_prod;
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

	public query func get_health() : async Health {
		let health : Health = {
			cycles = Utils.get_cycles_balance();
			memory_mb = Utils.get_memory_in_mb();
			heap_mb = Utils.get_heap_in_mb();
			assets_size = Map.size(assets);
		};

		return health;
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

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		assets_stable_storage := Iter.toArray(Map.entries(assets));
	};

	system func postupgrade() {
		assets := Map.fromIter<Asset_ID, Asset>(assets_stable_storage.vals(), thash);

		ignore Timer.recurringTimer(#seconds(300), clear_expired_chunks);

		assets_stable_storage := [];
	};
};
