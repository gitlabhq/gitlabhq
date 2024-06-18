package parser

import (
	"encoding/json"
)

// Property represents a property type
type Property int8

const (
	// DefinitionProp represents a definition property
	DefinitionProp Property = iota

	// ReferencesProp represents a references property
	ReferencesProp
)

// ResultSet represents a set of results, including hover information and a cache
type ResultSet struct {
	Hovers *Hovers
	Cache  *cache
}

// ResultSetRef represents a reference to a result set, including its ID and property
type ResultSetRef struct {
	ID       ID
	Property Property
}

// RawResultSetRef represents a raw reference to a result set, used for JSON unmarshalling
type RawResultSetRef struct {
	ResultSetID ID `json:"outV"`
	RefID       ID `json:"inV"`
}

// NewResultSet creates and returns a new ResultSet, initializing its hovers and cache
func NewResultSet() (*ResultSet, error) {
	hovers, err := NewHovers()
	if err != nil {
		return nil, err
	}

	cache, err := newCache("results-set-refs", &ResultSetRef{})
	if err != nil {
		return nil, err
	}

	return &ResultSet{
		Hovers: hovers,
		Cache:  cache,
	}, nil
}

// Read processes a line of input labeled with a specific type of result, adding it to the ResultSet
func (r *ResultSet) Read(label string, line []byte) error {
	switch label {
	case "textDocument/references":
		if err := r.addResultSetRef(line, ReferencesProp); err != nil {
			return err
		}
	case "textDocument/definition":
		if err := r.addResultSetRef(line, DefinitionProp); err != nil {
			return err
		}
	default:
		return r.Hovers.Read(label, line)
	}

	return nil
}

// RefByID retrieves a ResultSetRef by its ID from the cache
func (r *ResultSet) RefByID(refID ID) (*ResultSetRef, error) {
	var ref ResultSetRef
	if err := r.Cache.Entry(refID, &ref); err != nil {
		return nil, err
	}

	return &ref, nil
}

// Close closes the ResultSet, including its cache and hover information
func (r *ResultSet) Close() error {
	for _, err := range []error{
		r.Cache.Close(),
		r.Hovers.Close(),
	} {
		if err != nil {
			return err
		}
	}
	return nil
}

func (r *ResultSet) addResultSetRef(line []byte, property Property) error {
	var rawRef RawResultSetRef
	if err := json.Unmarshal(line, &rawRef); err != nil {
		return err
	}

	ref := &ResultSetRef{
		ID:       rawRef.ResultSetID,
		Property: property,
	}

	return r.Cache.SetEntry(rawRef.RefID, ref)
}

// IsDefinition checks if the ResultSetRef is a definition
func (r *ResultSetRef) IsDefinition() bool {
	return r.Property == DefinitionProp
}
