actor FileScalingManager = {
	let ACTOR_NAME : Text = "FileScalingManager";
	let VERSION : Nat = 1;

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};
};
