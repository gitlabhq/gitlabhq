package parser

import (
	"encoding/binary"
	"io"
	"os"
)

// This cache implementation is using a temp file to provide key-value data storage
// It allows to avoid storing intermediate calculations in RAM
// The stored data must be a fixed-size value or a slice of fixed-size values, or a pointer to such data
type cache struct {
	file      *os.File
	chunkSize int64
}

func newCache(filename string, data interface{}) (*cache, error) {
	f, err := os.CreateTemp("", filename)
	if err != nil {
		return nil, err
	}

	if err := os.Remove(f.Name()); err != nil {
		return nil, err
	}

	return &cache{file: f, chunkSize: int64(binary.Size(data))}, nil
}

func (c *cache) SetEntry(id ID, data interface{}) error {
	if err := c.setOffset(id); err != nil {
		return err
	}

	return binary.Write(c.file, binary.LittleEndian, data)
}

func (c *cache) Entry(id ID, data interface{}) error {
	if err := c.setOffset(id); err != nil {
		return err
	}

	return binary.Read(c.file, binary.LittleEndian, data)
}

func (c *cache) Close() error {
	return c.file.Close()
}

func (c *cache) setOffset(id ID) error {
	offset := int64(id) * c.chunkSize
	_, err := c.file.Seek(offset, io.SeekStart)

	return err
}
