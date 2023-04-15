import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";

module {
	public type Asset_ID = Text;
	public type Chunk_ID = Nat;

	public type AssetChunk = {
		batch_id : Text;
		checksum : Nat32;
		content : Blob;
		created : Int;
		filename : Text;
		id : Nat;
		order : Nat;
		owner : Principal;
	};

	type ContentEncoding = {
		#Identity;
		#GZIP;
	};

	public type AssetProperties = {
		content_encoding : ContentEncoding;
		content_type : Text;
		filename : Text;
		checksum : Nat32;
	};

	public type Asset = {
		canister_id : Text;
		chunks_size : Nat;
		content : ?[Blob];
		content_encoding : ContentEncoding;
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
		body : Blob;
		headers : [HeaderField];
		method : Text;
		url : Text;
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
