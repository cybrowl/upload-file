import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";

module {
	public type Asset_ID = Text;
	public type Chunk_ID = Nat;

	public type AssetChunk = {
		checksum : Nat;
		content : Blob;
		created : Int;
		filename : Text;
		id : Nat;
		order : Nat;
		owner : Principal;
	};

	public type ChunkInfo = { id : Chunk_ID; order : Nat };

	type ContentEncoding = {
		#Identity;
		#GZIP;
	};

	public type AssetProperties = {
		content_encoding : ContentEncoding;
		content_type : Text;
		filename : Text;
		checksum : Nat;
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

	public type Health = {
		cycles : Int;
		memory_mb : Int;
		heap_mb : Int;
		assets_size : Int;
	};

	public type CanisterInfo = {
		created : Int;
		id : Text;
		name : Text;
		parent_name : Text;
		health : ?Health;
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

	public type ErrCommitBatch = {
		#ChunkOwnerInvalid : Bool;
		#ChunkNotFound : Bool;
		#ChecksumInvalid : Bool;
	};

	public type ErrDeleteAsset = {
		#AssetNotFound : Bool;
		#NotAuthorized : Bool;
	};

	public type FileStorageActor = actor {
		is_full : shared () -> async Bool;
		get_health : query () -> async Health;
	};
};
