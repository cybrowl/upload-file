actor class FileStorage() = this {
	let ACTOR_NAME : Text = "FileStorage";
	let VERSION : Nat = 1;

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
