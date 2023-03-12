import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import FileStorage "FileStorage";
import Types "./types";

actor FileScalingManager = {
	let ACTOR_NAME : Text = "FileScalingManager";
	let CYCLE_AMOUNT : Nat = 1_000_000_000_000;
	let VERSION : Nat = 1;

	type FileStorageActor = Types.FileStorageActor;

	type CanisterInfo = {
		created : Int;
		id : Text;
		name : Text;
		parent_name : Text;
	};

	private let canister_records : HashMap.HashMap<Text, CanisterInfo> = HashMap.HashMap<Text, CanisterInfo>(
		0,
		Text.equal,
		Text.hash,
	);

	stable var file_storage_canister_id : Text = "";

	private func create_file_storage_canister() : async () {
		Cycles.add(CYCLE_AMOUNT);
		let file_storage_actor = await FileStorage.FileStorage();

		let principal = Principal.fromActor(file_storage_actor);
		file_storage_canister_id := Principal.toText(principal);

		let canister_child : CanisterInfo = {
			created = Time.now();
			id = file_storage_canister_id;
			name = "file_storage";
			parent_name = ACTOR_NAME;
		};

		canister_records.put(file_storage_canister_id, canister_child);
	};

	public shared ({ caller }) func get_file_storage_canister_id() : async Text {
		let file_storage_actor = actor (file_storage_canister_id) : FileStorageActor;

		switch (await file_storage_actor.is_full()) {
			case true {
				await create_file_storage_canister();

				return file_storage_canister_id;
			};
			case false {
				return file_storage_canister_id;
			};
		};
	};

	public query func get_canister_records() : async [CanisterInfo] {
		return Iter.toArray(canister_records.vals());
	};

	public shared ({ caller }) func init() : async Text {
		if (file_storage_canister_id == "") {
			await create_file_storage_canister();

			return "created new file storage canister";
		};

		return "file storage canister already exists";
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
