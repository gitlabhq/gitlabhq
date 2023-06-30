package parser

import (
	"encoding/json"
)

type Property int8

const (
	DefinitionProp Property = iota
	ReferencesProp
)

type ResultSet struct {
	Hovers *Hovers
	Cache  *cache
}

type ResultSetRef struct {
	Id       Id
	Property Property
}

type RawResultSetRef struct {
	ResultSetId Id `json:"outV"`
	RefId       Id `json:"inV"`
}

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

func (r *ResultSet) RefById(refId Id) (*ResultSetRef, error) {
	var ref ResultSetRef
	if err := r.Cache.Entry(refId, &ref); err != nil {
		return nil, err
	}

	return &ref, nil
}

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
		Id:       rawRef.ResultSetId,
		Property: property,
	}

	return r.Cache.SetEntry(rawRef.RefId, ref)
}

func (r *ResultSetRef) IsDefinition() bool {
	return r.Property == DefinitionProp
}
