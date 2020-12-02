package test

// Some useful const for testing purpose
const (
	// ObjectContent an example textual content
	ObjectContent = "TEST OBJECT CONTENT"
	// ObjectSize is the ObjectContent size
	ObjectSize = int64(len(ObjectContent))
	// Objectpath is an example remote object path (including bucket name)
	ObjectPath = "/bucket/object"
	// ObjectMD5 is ObjectContent MD5 hash
	ObjectMD5 = "42d000eea026ee0760677e506189cb33"
	// ObjectSHA1 is ObjectContent SHA1 hash
	ObjectSHA1 = "173cfd58c6b60cb910f68a26cbb77e3fc5017a6d"
	// ObjectSHA256 is ObjectContent SHA256 hash
	ObjectSHA256 = "b0257e9e657ef19b15eed4fbba975bd5238d651977564035ef91cb45693647aa"
	// ObjectSHA512 is ObjectContent SHA512 hash
	ObjectSHA512 = "51af8197db2047f7894652daa7437927bf831d5aa63f1b0b7277c4800b06f5e3057251f0e4c2d344ca8c2daf1ffc08a28dd3b2f5fe0e316d3fd6c3af58c34b97"
)
