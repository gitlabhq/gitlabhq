# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Unicode do
  using RSpec::Parameterized::TableSyntax

  describe described_class::BIDI_REGEXP do
    where(:bidi_string, :match) do
      "\u2066"       | true # left-to-right isolate
      "\u2067"       | true # right-to-left isolate
      "\u2068"       | true # first strong isolate
      "\u2069"       | true # pop directional isolate
      "\u202a"       | true # left-to-right embedding
      "\u202b"       | true # right-to-left embedding
      "\u202c"       | true # pop directional formatting
      "\u202d"       | true # left-to-right override
      "\u202e"       | true # right-to-left override
      "\u2066foobar" | true
      ""             | false
      "foo"          | false
      "\u2713"       | false # checkmark
    end

    with_them do
      let(:utf8_string) { bidi_string.encode("utf-8") }

      it "matches only the bidi characters" do
        expect(utf8_string.match?(subject)).to eq(match)
      end
    end
  end

  describe 'DANGEROUS_CHARS regex', feature_category: :workflow_catalog do
    subject(:regex) { described_class::DANGEROUS_CHARS }

    describe 'detects dangerous characters' do
      where(:name, :input) do
        # Control characters (except tab, LF, CR)
        "null byte"                | "\u0000"
        "bell"                     | "\u0007"
        "backspace"                | "\u0008"
        "vertical tab"             | "\u000B"
        "form feed"                | "\u000C"
        "escape"                   | "\u001B"
        "delete"                   | "\u007F"

        # Soft hyphen
        "soft hyphen"              | "\u00AD"

        # Zero-width space
        "ZWSP"                     | "\u200B"

        # Bidi overrides
        "LRE"                      | "\u202A"
        "RLE"                      | "\u202B"
        "PDF"                      | "\u202C"
        "LRO"                      | "\u202D"
        "RLO"                      | "\u202E"

        # Word joiner
        "word joiner"              | "\u2060"

        # Bidi isolates
        "LRI"                      | "\u2066"
        "RLI"                      | "\u2067"
        "FSI"                      | "\u2068"
        "PDI"                      | "\u2069"

        # BOM
        "BOM"                      | "\uFEFF"

        # Annotations
        "annotation anchor"        | "\uFFF9"
        "annotation separator"     | "\uFFFA"
        "annotation terminator"    | "\uFFFB"

        # Object replacement
        "object replacement"       | "\uFFFC"

        # Invisible math operators
        "invisible times"          | "\u2062"
        "invisible separator"      | "\u2063"
        "invisible plus"           | "\u2064"

        # Tag characters
        "tag space"                | "\u{E0020}"
        "language tag"             | "\u{E0001}"
        "tag character A"          | "\u{E0041}"
        "end of tag range"         | "\u{E007F}"

        # Variation selectors supplement
        "VS17"                     | "\u{E0100}"
        "VS256"                    | "\u{E01EF}"
        "middle of VS supplement"  | "\u{E0150}"

        # Line/paragraph separators
        "line separator"           | "\u2028"
        "paragraph separator"      | "\u2029"
      end

      with_them do
        it "detects #{params[:name]}" do
          is_expected.to match(input)
        end
      end
    end

    describe 'allows safe characters' do
      where(:name, :input) do
        # Allowed control characters
        "tab"                      | "\t"
        "newline"                  | "\n"
        "carriage return"          | "\r"

        # Text (legitimate)
        "ASCII text"               | 'Hello, World!'
        "numbers"                  | '1234567890'
        "punctuation"              | '!@#$%^&*()'
        "hyphen (not soft)"        | 'well-known'
        "Arabic"                   | 'مرحبا'
        "Hebrew"                   | 'שלום'
        "Greek"                    | 'Γειά σου'
        "Emoji"                    | '👋🌍🎉'
      end

      with_them do
        it "allows #{params[:name]}" do
          is_expected.not_to match(input)
        end
      end
    end

    describe 'edge cases' do
      it 'detects dangerous chars embedded in normal text' do
        dangerous = "normal\u200Btext"
        expect(dangerous).to match(regex)
      end

      it 'detects multiple dangerous chars' do
        dangerous = "\u202Eevil\u202C"
        expect(dangerous).to match(regex)
      end

      it 'detects dangerous char at start of string' do
        dangerous = "\uFEFFtext"
        expect(dangerous).to match(regex)
      end

      it 'detects dangerous char at end of string' do
        dangerous = "text\u200B"
        expect(dangerous).to match(regex)
      end
    end
  end
end
