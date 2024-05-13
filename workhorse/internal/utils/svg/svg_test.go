package svg

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestIs(t *testing.T) {
	testCases := []struct {
		name   string
		input  []byte
		expect bool
	}{
		{
			name:   "Valid SVG",
			input:  []byte(`<svg width="100" height="100"></svg>`),
			expect: true,
		},
		{
			name:   "Invalid SVG - Missing SVG tag",
			input:  []byte(`<html><body><h1>Hello, World!</h1></body></html>`),
			expect: false,
		},
		{
			name:   "Invalid SVG - Random Bytes",
			input:  []byte("random binary data"),
			expect: false,
		},
		// Additional test cases from upstream library https://github.com/h2non/go-is-svg/blob/master/svg_test.go
		{
			name:   "Valid SVG with comments",
			input:  []byte(`<!-- This is a comment --><svg width="100" height="100"></svg>`),
			expect: true,
		},
		{
			name:   "Invalid SVG bytes",
			input:  []byte{0},
			expect: false,
		},
		{
			name:   "Invalid SVG bytes",
			input:  []byte{0x00, 0x01, 0x03, 0x04},
			expect: false,
		},
		{
			name: "Valid SVG",
			input: []byte(`<?xml version="1.0" encoding="utf-8"?>
			<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
			<svg version="1.1" baseProfile="basic" id="svg2" xmlns:svg="http://www.w3.org/2000/svg" viewBox="0 0 900 900" xml:space="preserve">
				<path id="path482" fill="none" d="M184.013,144.428"/>
				<path id="path6" fill="#FFFFFF" stroke="#000000" stroke-width="0.172" d="917-66.752-80.957C40.928,326.18,72.326,313.197,108.956,403.826z"/>
			</svg>`),
			expect: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			got := Is(tc.input)
			require.Equal(t, tc.expect, got)
		})
	}
}
