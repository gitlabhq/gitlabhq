// Package htmlstream provides streaming, attribute-scoped rewrites of HTML
// documents.
//
// It rewrites the value of a named attribute (for example href) without
// buffering the whole document, so it can process very large responses (for
// example PyPI PEP 503 simple-index pages) without holding one in memory. Only
// the current token is buffered, bounded by maxTokenBytes.
package htmlstream

import (
	"io"

	"golang.org/x/net/html"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/prefixrewrite"
)

// maxTokenBytes bounds the tokenizer's internal buffer. A real simple index is
// millions of small tokens, but the tokenizer grows to fit the largest single
// one, so without a ceiling an upstream response that is one enormous text node
// or attribute value would buffer in full -- inside Workhorse, which serves
// every request. Past this, Next returns ErrBufferExceeded instead of growing.
// Chosen far above any genuine index entry, which runs to a few hundred bytes.
const maxTokenBytes = 1 << 20 // 1 MiB

// Transform streams HTML from r to w, replacing the first matching prefix in
// froms with the to prefix, in the value of every attribute named key. Prefixes
// are matched case-insensitively, since they name a scheme and optionally a
// host, both of which are case-insensitive.
//
// Several prefixes map to one replacement so that both `https://` and `http://`
// entries route back through GitLab. Dropping the scheme on the way is
// deliberate: the caller rebuilds the upstream URL over https.
//
// Only start and self-closing tags are re-serialized; every other token is
// copied through byte for byte. That matters for raw-text elements: the
// tokenizer reports <script> and <style> bodies as text tokens, and
// re-serializing those would escape their contents (`a < b` becoming
// `a &lt; b`), which is not valid JavaScript or CSS.
func Transform(r io.Reader, w io.Writer, key string, froms []string, to string) error {
	rewriter := prefixrewrite.New(froms, to)
	if rewriter.Empty() {
		_, err := io.Copy(w, r)
		return err
	}

	z := html.NewTokenizer(r)
	z.SetMaxBuf(maxTokenBytes)

	for {
		tokenType := z.Next()
		if tokenType == html.ErrorToken {
			if z.Err() == io.EOF {
				return nil
			}
			return z.Err()
		}

		if err := writeToken(w, z, tokenType, key, rewriter); err != nil {
			return err
		}
	}
}

// writeToken copies the tokenizer's current token to w, rewriting the named
// attribute on tags. The token type has to be tested before calling Token,
// which unescapes text in place and so may change the bytes Raw returns.
func writeToken(w io.Writer, z *html.Tokenizer, tokenType html.TokenType, key string, rewriter prefixrewrite.Rewriter) error {
	if tokenType != html.StartTagToken && tokenType != html.SelfClosingTagToken {
		_, err := w.Write(z.Raw())
		return err
	}

	tok := z.Token()
	for i := range tok.Attr {
		if tok.Attr[i].Key != key {
			continue
		}

		if rewritten, ok := rewriter.Apply(tok.Attr[i].Val); ok {
			tok.Attr[i].Val = rewritten
		}
	}

	_, err := io.WriteString(w, tok.String())
	return err
}
