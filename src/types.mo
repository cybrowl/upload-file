import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {
	public type Asset_ID = Nat;
	public type Chunk_ID = Nat;

	public type AssetChunk = {
		batch_id : Text;
		content : Blob;
		created : Int;
		file_name : Text;
		order : Nat;
		owner : Principal;
	};

	public type AssetProperties = {
		// sha256 : Text;
		content_encoding : Text;
		content_type : Text;
		file_name : Text;
	};

	public type Asset = {
		canister_id : Text;
		content_type : Text;
		created : Int;
		content : ?[Blob];
		content_size : Nat;
		file_name : Text;
		id : Nat;
		owner : Principal;
	};

	type HeaderField = (Text, Text);

	public type HttpRequest = {
		url : Text;
		method : Text;
		body : Blob;
		headers : [HeaderField];
	};

	public type HttpResponse = {
		body : [Nat8];
		headers : [HeaderField];
		status_code : Nat16;
		streaming_strategy : ?StreamingStrategy;
	};

	public type CreateStrategyArgs = {
		asset_id : Nat;
		chunk_index : Nat;
		data_chunks_size : Nat;
	};

	public type StreamingCallbackToken = {
		asset_id : Nat;
		chunk_index : Nat;
		content_encoding : Text;
	};

	public type StreamingStrategy = {
		#Callback : {
			token : StreamingCallbackToken;
			callback : shared () -> async ();
		};
	};

	public type StreamingCallbackHttpResponse = {
		body : Blob;
		token : ?StreamingCallbackToken;
	};
};
