pragma solidity ^0.8.0;

contract DUpload {
    struct Document {
        address docOwner;
        string name;
        string description;
        string hash;
		uint256 timestamp;
		bool publicDoc;
		string tag;
		uint256 index;
    }

    struct User {
        string userName;
        uint256 allowedUploads;
        mapping(uint256 => Document) documents;
        uint256 documentCount;
		uint256 documentCountLocked;
    }
    mapping(string => Document) public tagToDocument;
    mapping(address => User) users;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function incrementAllowedUploads(address user, uint256 additionalUploads) external {
        require(msg.sender == owner, "Not authorized.");
        users[user].allowedUploads += additionalUploads;
    }

    function uploadDocument(address user, string calldata tag, string calldata name, string calldata description, string calldata documentHash, bool publicDoc) external {
        require(msg.sender == owner, "Not authorized.");
        require(users[user].allowedUploads > 0, "No allowed uploads for you.");
		require(bytes(name).length > 0, "Name cannot be empty.");
		require(bytes(description).length > 0, "Description cannot be empty.");
		require(bytes(documentHash).length > 0, "Document hash cannot be empty.");
	
        uint256 index = users[user].documentCountLocked;
        users[user].documents[index] = Document(user, name, description, documentHash,block.timestamp,publicDoc, tag,index);
        tagToDocument[tag] = users[user].documents[index];
        users[user].allowedUploads -= 1;
        users[user].documentCount += 1;
		users[user].documentCountLocked += 1;

    }

    function deleteDocument(address user, string calldata tag) external {
		//DOES NOT NECCASSARYLY DELETE LAST ADDED DOCUMENT, JUST BY THE TAG GIVEN.
        require(msg.sender == owner, "Not authorized.");
		require(users[user].documentCount > 0, "No documents to delete.");
	
        Document storage document = tagToDocument[tag];
		
		require(bytes(document.hash).length > 0, "Document not found.");
		require(document.docOwner == user, "Not your document.");


		delete users[user].documents[document.index];
		delete tagToDocument[tag];
        users[user].documentCount -= 1;
    }

    function getAllDocuments(address user) external view returns (Document[] memory) {
		Document[] memory docs = new Document[](users[user].documentCount);
		for (uint256 i = 0; i < users[user].documentCount; i++) {
			docs[i] = users[user].documents[i];
		}
		return docs;
    }

    function getUploadedDocumentCount(address user) external view returns (uint256) {
        require(msg.sender == owner, "Not authorized.");
        
        return users[user].documentCount;
    }

    function getAllowedUploads(address user) external view returns (uint256) {
        require(msg.sender == owner, "Not authorized.");

        return users[user].allowedUploads;
    }
    
    function getOwnDoc(address user, string calldata tag) external returns (Document memory) {
		require(msg.sender == owner, "Not authorized");
		Document storage document = tagToDocument[tag];
		require(bytes(document.hash).length > 0, "Document not found.");
		require(document.docOwner == user, "Not your document.");
		return document;
	}

	function getOtherDoc(string calldata tag) external returns (Document memory) {
		require(msg.sender == owner, "Not authorized");
		Document storage document = tagToDocument[tag];
		require(bytes(document.hash).length > 0, "Document not found.");
		require(document.publicDoc, "This is a private document.");
		return document;
	}
}