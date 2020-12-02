package filestore

import (
	"crypto/md5"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/hex"
	"hash"
	"io"
)

var hashFactories = map[string](func() hash.Hash){
	"md5":    md5.New,
	"sha1":   sha1.New,
	"sha256": sha256.New,
	"sha512": sha512.New,
}

type multiHash struct {
	io.Writer
	hashes map[string]hash.Hash
}

func newMultiHash() (m *multiHash) {
	m = &multiHash{}
	m.hashes = make(map[string]hash.Hash)

	var writers []io.Writer
	for hash, hashFactory := range hashFactories {
		writer := hashFactory()

		m.hashes[hash] = writer
		writers = append(writers, writer)
	}

	m.Writer = io.MultiWriter(writers...)
	return m
}

func (m *multiHash) finish() map[string]string {
	h := make(map[string]string)
	for hashName, hash := range m.hashes {
		checksum := hash.Sum(nil)
		h[hashName] = hex.EncodeToString(checksum)
	}
	return h
}
