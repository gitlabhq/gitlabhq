package test

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/xml"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"sync"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore"
)

type partsEtagMap map[int]string

// ObjectstoreStub is a testing implementation of ObjectStore.
// Instead of storing objects it will just save md5sum.
type ObjectstoreStub struct {
	// bucket contains md5sum of uploaded objects
	bucket map[string]string
	// overwriteMD5 contains overwrites for md5sum that should be return instead of the regular hash
	overwriteMD5 map[string]string
	// multipart is a map of MultipartUploads
	multipart map[string]partsEtagMap
	// HTTP header sent along request
	headers map[string]*http.Header

	puts    int
	deletes int

	m sync.Mutex
}

// StartObjectStore will start an ObjectStore stub
func StartObjectStore() (*ObjectstoreStub, *httptest.Server) {
	return StartObjectStoreWithCustomMD5(make(map[string]string))
}

// StartObjectStoreWithCustomMD5 will start an ObjectStore stub: md5Hashes contains overwrites for md5sum that should be return on PutObject
func StartObjectStoreWithCustomMD5(md5Hashes map[string]string) (*ObjectstoreStub, *httptest.Server) {
	os := &ObjectstoreStub{
		bucket:       make(map[string]string),
		multipart:    make(map[string]partsEtagMap),
		overwriteMD5: make(map[string]string),
		headers:      make(map[string]*http.Header),
	}

	for k, v := range md5Hashes {
		os.overwriteMD5[k] = v
	}

	return os, httptest.NewServer(os)
}

// PutsCnt counts PutObject invocations
func (o *ObjectstoreStub) PutsCnt() int {
	o.m.Lock()
	defer o.m.Unlock()

	return o.puts
}

// DeletesCnt counts DeleteObject invocation of a valid object
func (o *ObjectstoreStub) DeletesCnt() int {
	o.m.Lock()
	defer o.m.Unlock()

	return o.deletes
}

// GetObjectMD5 return the calculated MD5 of the object uploaded to path
// it will return an empty string if no object has been uploaded on such path
func (o *ObjectstoreStub) GetObjectMD5(path string) string {
	o.m.Lock()
	defer o.m.Unlock()

	return o.bucket[path]
}

// GetHeader returns a given HTTP header of the object uploaded to the path
func (o *ObjectstoreStub) GetHeader(path, key string) string {
	o.m.Lock()
	defer o.m.Unlock()

	if val, ok := o.headers[path]; ok {
		return val.Get(key)
	}

	return ""
}

// InitiateMultipartUpload prepare the ObjectstoreStob to receive a MultipartUpload on path
// It will return an error if a MultipartUpload is already in progress on that path
// InitiateMultipartUpload is only used during test setup.
// Workhorse's production code does not know how to initiate a multipart upload.
//
// Real S3 multipart uploads are more complicated than what we do here,
// but this is enough to verify that workhorse's production code behaves as intended.
func (o *ObjectstoreStub) InitiateMultipartUpload(path string) error {
	o.m.Lock()
	defer o.m.Unlock()

	if o.multipart[path] != nil {
		return fmt.Errorf("MultipartUpload for %q already in progress", path)
	}

	o.multipart[path] = make(partsEtagMap)
	return nil
}

// IsMultipartUpload check if the given path has a MultipartUpload in progress
func (o *ObjectstoreStub) IsMultipartUpload(path string) bool {
	o.m.Lock()
	defer o.m.Unlock()

	return o.isMultipartUpload(path)
}

// isMultipartUpload is the lock free version of IsMultipartUpload
func (o *ObjectstoreStub) isMultipartUpload(path string) bool {
	return o.multipart[path] != nil
}

func (o *ObjectstoreStub) removeObject(w http.ResponseWriter, r *http.Request) {
	o.m.Lock()
	defer o.m.Unlock()

	objectPath := r.URL.Path
	if o.isMultipartUpload(objectPath) {
		o.deletes++
		delete(o.multipart, objectPath)

		w.WriteHeader(200)
	} else if _, ok := o.bucket[objectPath]; ok {
		o.deletes++
		delete(o.bucket, objectPath)

		w.WriteHeader(200)
	} else {
		w.WriteHeader(404)
	}
}

func (o *ObjectstoreStub) putObject(w http.ResponseWriter, r *http.Request) {
	o.m.Lock()
	defer o.m.Unlock()

	objectPath := r.URL.Path

	etag, overwritten := o.overwriteMD5[objectPath]
	if !overwritten {
		hasher := md5.New()
		io.Copy(hasher, r.Body)

		checksum := hasher.Sum(nil)
		etag = hex.EncodeToString(checksum)
	}

	o.headers[objectPath] = &r.Header
	o.puts++
	if o.isMultipartUpload(objectPath) {
		pNumber := r.URL.Query().Get("partNumber")
		idx, err := strconv.Atoi(pNumber)
		if err != nil {
			http.Error(w, fmt.Sprintf("malformed partNumber: %v", err), 400)
			return
		}

		o.multipart[objectPath][idx] = etag
	} else {
		o.bucket[objectPath] = etag
	}

	w.Header().Set("ETag", etag)
	w.WriteHeader(200)
}

func MultipartUploadInternalError() *objectstore.CompleteMultipartUploadError {
	return &objectstore.CompleteMultipartUploadError{Code: "InternalError", Message: "malformed object path"}
}

func (o *ObjectstoreStub) completeMultipartUpload(w http.ResponseWriter, r *http.Request) {
	o.m.Lock()
	defer o.m.Unlock()

	objectPath := r.URL.Path

	multipart := o.multipart[objectPath]
	if multipart == nil {
		http.Error(w, "Unknown MultipartUpload", 404)
		return
	}

	buf, err := ioutil.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}

	var msg objectstore.CompleteMultipartUpload
	err = xml.Unmarshal(buf, &msg)
	if err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	for _, part := range msg.Part {
		etag := multipart[part.PartNumber]
		if etag != part.ETag {
			msg := fmt.Sprintf("ETag mismatch on part %d. Expected %q got %q", part.PartNumber, etag, part.ETag)
			http.Error(w, msg, 400)
			return
		}
	}

	etag, overwritten := o.overwriteMD5[objectPath]
	if !overwritten {
		etag = "CompleteMultipartUploadETag"
	}

	o.bucket[objectPath] = etag
	delete(o.multipart, objectPath)

	w.Header().Set("ETag", etag)
	split := strings.SplitN(objectPath[1:], "/", 2)
	if len(split) < 2 {
		encodeXMLAnswer(w, MultipartUploadInternalError())
		return
	}

	bucket := split[0]
	key := split[1]
	answer := objectstore.CompleteMultipartUploadResult{
		Location: r.URL.String(),
		Bucket:   bucket,
		Key:      key,
		ETag:     etag,
	}
	encodeXMLAnswer(w, answer)
}

func encodeXMLAnswer(w http.ResponseWriter, answer interface{}) {
	w.Header().Set("Content-Type", "text/xml")

	enc := xml.NewEncoder(w)
	if err := enc.Encode(answer); err != nil {
		http.Error(w, err.Error(), 500)
	}
}

func (o *ObjectstoreStub) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Body != nil {
		defer r.Body.Close()
	}

	fmt.Println("ObjectStore Stub:", r.Method, r.URL.String())

	if r.URL.Path == "" {
		http.Error(w, "No path provided", 404)
		return
	}

	switch r.Method {
	case "DELETE":
		o.removeObject(w, r)
	case "PUT":
		o.putObject(w, r)
	case "POST":
		o.completeMultipartUpload(w, r)
	default:
		w.WriteHeader(404)
	}
}
