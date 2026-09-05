# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rouge::Formatters::HTMLGitlab, feature_category: :source_code_management do
  describe '#format' do
    subject(:formatted_tokens) { described_class.format(tokens, **options) }

    let(:lang) { 'ruby' }
    let(:lexer) { Rouge::Lexer.find_fancy(lang) }
    let(:tokens) { lexer.lex("def hello", continue: false) }
    let(:options) { { tag: lang } }

    context 'when svg and indexes are present to trim' do
      let(:options) { { tag: lang, ellipsis_indexes: [0], ellipsis_svg: "svg_icon" } }

      it 'returns highlighted ruby code with svg' do
        code = %q(<span id="LC1" class="line" data-lang="ruby"><span class="k">def</span> <span class="nf">hello</span><span class="gl-px-2 gl-rounded-base gl-mx-2 gl-bg-gray-100 gl-cursor-help has-tooltip" title="Content has been trimmed">svg_icon</span></span>)

        is_expected.to eq(code)
      end
    end

    it 'returns highlighted ruby code' do
      code = %q(<span id="LC1" class="line" data-lang="ruby"><span class="k">def</span> <span class="nf">hello</span></span>)

      is_expected.to eq(code)
    end

    context 'when options are empty' do
      let(:options) { {} }

      it 'returns highlighted code with plaintext default' do
        code = %q(<span id="LC1" class="line" data-lang="plaintext"><span class="k">def</span> <span class="nf">hello</span></span>)

        is_expected.to eq(code)
      end
    end

    context 'when suppress_line_ids is true' do
      let(:options) { { suppress_line_ids: true } }

      it 'returns highlighted code without line id attribute' do
        code = %q(<span class="line" data-lang="plaintext"><span class="k">def</span> <span class="nf">hello</span></span>)

        is_expected.to eq(code)
      end
    end

    context 'when suppress_line_ids is true with a language tag' do
      let(:options) { { suppress_line_ids: true, tag: lang } }

      it 'returns highlighted code with data-lang but without line id attribute' do
        code = %q(<span class="line" data-lang="ruby"><span class="k">def</span> <span class="nf">hello</span></span>)

        is_expected.to eq(code)
      end
    end

    context 'when line number is provided' do
      let(:options) { { tag: lang, line_number: 10 } }

      it 'returns highlighted ruby code with correct line number' do
        code = %q(<span id="LC10" class="line" data-lang="ruby"><span class="k">def</span> <span class="nf">hello</span></span>)

        is_expected.to eq(code)
      end
    end

    context 'when unicode control characters are used' do
      let(:lang) { 'javascript' }
      let(:tokens) { lexer.lex(code, continue: false) }
      let(:code) do
        <<~JS
          #!/usr/bin/env node

          var accessLevel = "user";
          if (accessLevel != "user‮ ⁦// Check if admin⁩ ⁦") {
              console.log("You are an admin.");
          }
        JS
      end

      it 'highlights the control characters' do
        message = "Potentially unwanted character detected: Unicode BiDi Control"

        is_expected.to include(%(<span class="unicode-bidi has-tooltip" data-toggle="tooltip" title="#{message}">)).exactly(4).times
      end
    end

    context 'when space characters and zero-width spaces are used' do
      let(:lang) { 'ruby' }
      let(:tokens) { lexer.lex(code, continue: false) }

      let(:code) do
        <<~JS
          def\u00a0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000hello
        JS
      end

      it 'replaces the space characters with spaces' do
        is_expected.to eq(
          "<span id=\"LC1\" class=\"line\" data-lang=\"ruby\">" \
          "<span class=\"k\">def</span><span class=\"err\">                </span><span class=\"n\">hello</span>" \
          "</span>"
        )
      end
    end

    context 'with valid ASCII containing HTML metacharacters' do
      let(:tokens) { [[Rouge::Token['Text'], '<script>&"']] }

      it 'escapes the token value' do
        is_expected.to eq('<span id="LC1" class="line" data-lang="ruby">&lt;script&gt;&amp;"</span>')
      end
    end

    context 'with valid non-target multibyte UTF-8' do
      let(:tokens) { [[Rouge::Token['Text'], 'café 日本語 👋']] }

      it 'preserves the token value' do
        is_expected.to eq('<span id="LC1" class="line" data-lang="ruby">café 日本語 👋</span>')
      end
    end

    context 'with all non-ASCII space characters' do
      let(:tokens) do
        [[Rouge::Token['Text'], "a\u00A0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000b"]]
      end

      it 'replaces every character with an ASCII space' do
        is_expected.to eq(%(<span id="LC1" class="line" data-lang="ruby">a#{' ' * 16}b</span>))
      end
    end

    context 'with all bidi control characters' do
      let(:bidi_characters) { "\u061C\u200E\u200F\u202A\u202B\u202C\u202D\u202E\u2066\u2067\u2068\u2069" }
      let(:tokens) { [[Rouge::Token['Text'], bidi_characters]] }

      it 'wraps every character in input order' do
        warning = 'Potentially unwanted character detected: Unicode BiDi Control'
        wrapped_characters = bidi_characters.chars.map do |character|
          %(<span class="unicode-bidi has-tooltip" data-toggle="tooltip" title="#{warning}">#{character}</span>)
        end.join

        is_expected.to eq(%(<span id="LC1" class="line" data-lang="ruby">#{wrapped_characters}</span>))
      end
    end

    context 'with an invalid UTF-8 token value' do
      let(:tokens) { [[Rouge::Token['Text'], (+"invalid\xFF").force_encoding(Encoding::UTF_8)]] }

      it 'retains the inherited formatter error' do
        expect { formatted_tokens }.to raise_error(ArgumentError, 'invalid byte sequence in UTF-8')
      end
    end

    context 'with an ASCII-incompatible token value' do
      let(:tokens) { [[Rouge::Token['Text'], "text\n".encode(Encoding::UTF_16LE)]] }

      it 'retains the inherited formatter error' do
        expect { formatted_tokens }.to raise_error(Encoding::CompatibilityError)
      end
    end

    context 'with an incompatible ASCII-8BIT token value' do
      let(:tokens) { [[Rouge::Token['Text'], "binary\xFF".b]] }

      it 'retains the inherited formatter error' do
        expect { formatted_tokens }.to raise_error(Encoding::CompatibilityError)
      end
    end
  end
end
