import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {
	public type Asset_ID = Text;
	public type Chunk_ID = Nat;

	public type AssetChunk = {
		batch_id : Text;
		content : Blob;
		created : Int;
		filename : Text;
		id : Nat;
		order : Nat;
		owner : Principal;
	};

	public type AssetProperties = {
		// sha256 : Text;
		content_encoding : Text;
		content_type : Text;
		filename : Text;
	};

	public type Asset = {
		canister_id : Text;
		chunks_size : Nat;
		content : ?[Blob];
		content_size : Nat;
		content_type : Text;
		created : Int;
		filename : Text;
		id : Text;
		owner : Text;
		url : Text;
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
		asset_id : Text;
		chunk_index : Nat;
		data_chunks_size : Nat;
	};

	public type StreamingCallbackToken = {
		asset_id : Text;
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

	public type FileStorageActor = actor {
		is_full : shared () -> async Bool;
	};
};
