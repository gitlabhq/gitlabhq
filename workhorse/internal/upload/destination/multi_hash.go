package destination

import (
	"crypto/md5"  //nolint:gosec // G501: MD5 used for content checksums and S3 ETag compatibility, not security
	"crypto/sha1" //nolint:gosec // G505: SHA1 used for content checksums, not security
	"crypto/sha256"
	"crypto/sha512"
	"encoding/hex"
	"hash"
	"io"
	"slices"
)

var hashFactories = map[string]func() hash.Hash{
	"md5":    md5.New,
	"sha1":   sha1.New,
	"sha256": sha256.New,
	"sha512": sha512.New,
}

type multiHash struct {
	io.Writer
	hashes map[string]hash.Hash
}

func permittedHashFunction(hashFunctions []string, hash string) bool {
	if len(hashFunctions) == 0 {
		return true
	}

	return slices.Contains(hashFunctions, hash)
}

func newMultiHash(hashFunctions []string) *multiHash {
	hashes := make(map[string]hash.Hash)

	var writers []io.Writer
	for hashName, hashFactory := range hashFactories {
		if !permittedHashFunction(hashFunctions, hashName) {
			continue
		}

		writer := hashFactory()

		hashes[hashName] = writer
		writers = append(writers, writer)
	}

	var w io.Writer
	if len(writers) == 1 {
		w = writers[0]
	} else {
		w = io.MultiWriter(writers...)
	}
	return &multiHash{
		Writer: w,
		hashes: hashes,
	}
}

func (m *multiHash) finish() map[string]string {
	h := make(map[string]string)
	for hashName, hash := range m.hashes {
		checksum := hash.Sum(nil)
		h[hashName] = hex.EncodeToString(checksum)
	}
	return h
}
