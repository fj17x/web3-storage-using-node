pragma solidity ^0.8.0;

contract DUpload {
    struct Document {
        uint256 index;
        string name;
        string description;
        string hash;
		uint256 timestamp;
    }

    struct User {
        string userName;
        uint256 allowedUploads;
        mapping(uint256 => Document) documents;
        uint256 documentCount;
    }

    mapping(address => User) users;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function incrementAllowedUploads(address user, uint256 additionalUploads) external {
        require(msg.sender == owner, "Not authorized.");

        users[user].allowedUploads += additionalUploads;
    }

    function uploadDocument(address user, string calldata name, string calldata description, string calldata documentHash) external {
        require(msg.sender == owner, "Not authorized.");
        require(users[user].allowedUploads > 0, "No allowed uploads for you.");
		require(bytes(name).length > 0, "Name cannot be empty.");
		require(bytes(description).length > 0, "Description cannot be empty.");
		require(bytes(documentHash).length > 0, "Document hash cannot be empty.");
	
        uint256 index = users[user].documentCount;
        users[user].documents[index] = Document(index, name, description, documentHash,block.timestamp);
        users[user].allowedUploads -= 1;
        users[user].documentCount += 1;
    }

    function deleteDocument(address user, uint256 index) external {
        require(msg.sender == owner, "Not authorized.");
		require(users[user].documentCount > 0, "No documents to delete.");
        require(index < users[user].documentCount, "Index out of bounds");

        if (index != users[user].documentCount - 1) {
            users[user].documents[index] = users[user].documents[users[user].documentCount - 1];
            users[user].documents[index].index = index;
        }
        delete users[user].documents[users[user].documentCount - 1];
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
}