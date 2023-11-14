# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::EncodingHelper, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:ext_class) { Class.new { extend Gitlab::EncodingHelper } }
  let(:binary_string) { File.read(Rails.root + "spec/fixtures/dk.png") }

  describe '#encode!' do
    [
      ["nil", nil, nil],
      ["empty string", "".encode("ASCII-8BIT"), "".encode("UTF-8")],
      ["invalid utf-8 encoded string", (+"my bad string\xE5").force_encoding("UTF-8"), "my bad string"],
      ["frozen non-ascii string", (+"é").force_encoding("ASCII-8BIT").freeze, "é".encode("UTF-8")],
      [
        'leaves ascii only string as is',
        'ascii only string',
        'ascii only string'
      ],
      [
        'leaves valid utf8 string as is',
        'multibyte string №∑∉',
        'multibyte string №∑∉'
      ],
      [
        'removes invalid bytes from ASCII-8bit encoded multibyte string. This can occur when a git diff match line truncates in the middle of a multibyte character. This occurs after the second word in this example. The test string is as short as we can get while still triggering the error condition when not looking at `detect[:confidence]`.',
        (+"mu ns\xC3\n Lorem ipsum dolor sit amet, consectetur adipisicing ut\xC3\xA0y\xC3\xB9abcd\xC3\xB9efg kia elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non p\n {: .normal_pn}\n \n-Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in\n# *Lorem ipsum\xC3\xB9l\xC3\xB9l\xC3\xA0 dolor\xC3\xB9k\xC3\xB9 sit\xC3\xA8b\xC3\xA8 N\xC3\xA8 amet b\xC3\xA0d\xC3\xAC*\n+# *consectetur\xC3\xB9l\xC3\xB9l\xC3\xA0 adipisicing\xC3\xB9k\xC3\xB9 elit\xC3\xA8b\xC3\xA8 N\xC3\xA8 sed do\xC3\xA0d\xC3\xAC*{: .italic .smcaps}\n \n \xEF\x9B\xA1 eiusmod tempor incididunt, ut\xC3\xAAn\xC3\xB9 labore et dolore. Tw\xC4\x83nj\xC3\xAC magna aliqua. Ut enim ad minim veniam\n {: .normal}\n@@ -9,5 +9,5 @@ quis nostrud\xC3\xAAt\xC3\xB9 exercitiation ullamco laboris m\xC3\xB9s\xC3\xB9k\xC3\xB9abc\xC3\xB9 nisi ").force_encoding('ASCII-8BIT'),
        "mu ns\n Lorem ipsum dolor sit amet, consectetur adipisicing ut\xC3\xA0y\xC3\xB9abcd\xC3\xB9efg kia elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non p\n {: .normal_pn}\n \n-Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in\n# *Lorem ipsum\xC3\xB9l\xC3\xB9l\xC3\xA0 dolor\xC3\xB9k\xC3\xB9 sit\xC3\xA8b\xC3\xA8 N\xC3\xA8 amet b\xC3\xA0d\xC3\xAC*\n+# *consectetur\xC3\xB9l\xC3\xB9l\xC3\xA0 adipisicing\xC3\xB9k\xC3\xB9 elit\xC3\xA8b\xC3\xA8 N\xC3\xA8 sed do\xC3\xA0d\xC3\xAC*{: .italic .smcaps}\n \n \xEF\x9B\xA1 eiusmod tempor incididunt, ut\xC3\xAAn\xC3\xB9 labore et dolore. Tw\xC4\x83nj\xC3\xAC magna aliqua. Ut enim ad minim veniam\n {: .normal}\n@@ -9,5 +9,5 @@ quis nostrud\xC3\xAAt\xC3\xB9 exercitiation ullamco laboris m\xC3\xB9s\xC3\xB9k\xC3\xB9abc\xC3\xB9 nisi "
      ],
      [
        'string with detected encoding that is not supported in Ruby',
        "\xFFe,i\xFF,\xB8oi,'\xB8,\xFF,-",
        "--broken encoding: IBM420_ltr"
      ]
    ].each do |description, test_string, xpect|
      it description do
        expect(ext_class.encode!(test_string)).to eq(xpect)
      end
    end

    it 'leaves binary string as is' do
      expect(ext_class.encode!(binary_string)).to eq(binary_string)
    end

    context 'with corrupted diff' do
      let(:project) { create(:project, :empty_repo) }
      let(:repository) { project.repository }
      let(:content) { fixture_file('encoding/Japanese.md') }
      let(:corrupted_diff) do
        commit_a = repository.create_file(
          project.creator,
          'Japanese.md',
          content,
          branch_name: 'HEAD',
          message: 'Create Japanese.md'
        )
        commit_b = repository.update_file(
          project.creator,
          'Japanese.md',
          content.sub('[TODO: Link]', '[現在作業中です: Link]'),
          branch_name: 'HEAD',
          message: 'Update Japanese.md'
        )

        repository.diff(commit_a, commit_b).map(&:diff).join
      end

      let(:cleaned_diff) do
        corrupted_diff.dup.force_encoding('UTF-8')
          .encode!('UTF-8', invalid: :replace, replace: '')
      end

      let(:encoded_diff) do
        described_class.encode!(corrupted_diff.dup)
      end

      it 'does not corrupt data but remove invalid characters' do
        expect(encoded_diff).to eq(cleaned_diff)
      end
    end
  end

  describe '#encode_utf8_no_detect' do
    where(:input, :expected) do
      "abcd" | "abcd"
      "ǲǲǲ" | "ǲǲǲ"
      "\xC7\xB2\xC7ǲǲǲ" | "ǲ�ǲǲǲ"
      "🐤🐤🐤🐤\xF0\x9F\x90" | "🐤🐤🐤🐤�"
    end

    with_them do
      it 'drops invalid UTF-8' do
        expect(ext_class.encode_utf8_no_detect(input.dup.force_encoding(Encoding::ASCII_8BIT))).to eq(expected)
        expect(ext_class.encode_utf8_no_detect(input)).to eq(expected)
      end
    end
  end

  describe '#encode_utf8_with_escaping!' do
    where(:input, :expected) do
      "abcd" | "abcd"
      "ǲǲǲ" | "ǲǲǲ"
      "\xC7\xB2\xC7ǲǲǲ" | "ǲ%C7ǲǲǲ"
      "🐤🐤🐤🐤\xF0\x9F\x90" | "🐤🐤🐤🐤%F0%9F%90"
      "\xD0\x9F\xD1\x80 \x90" | "Пр %90"
      "\x41" | "A"
    end

    with_them do
      it 'escapes invalid UTF-8' do
        expect(ext_class.encode_utf8_with_escaping!(input.dup.force_encoding(Encoding::ASCII_8BIT))).to eq(expected)
        expect(ext_class.encode_utf8_with_escaping!(input)).to eq(expected)
      end
    end
  end

  describe '#encode_utf8' do
    [
      ["nil", nil, nil],
      ["empty string", "".encode("ASCII-8BIT"), "".encode("UTF-8")],
      ["invalid utf-8 encoded string", (+"my bad string\xE5").force_encoding("UTF-8"), "my bad stringå"],
      [
        "encodes valid utf8 encoded string to utf8",
        "λ, λ, λ".encode("UTF-8"),
        "λ, λ, λ".encode("UTF-8")
      ],
      [
        "encodes valid ASCII-8BIT encoded string to utf8",
        "ascii only".encode("ASCII-8BIT"),
        "ascii only".encode("UTF-8")
      ],
      [
        "encodes valid ISO-8859-1 encoded string to utf8",
        "Rüby ist eine Programmiersprache. Wir verlängern den text damit ICU die Sprache erkennen kann.".encode("ISO-8859-1", "UTF-8"),
        "Rüby ist eine Programmiersprache. Wir verlängern den text damit ICU die Sprache erkennen kann.".encode("UTF-8")
      ],
      [
        # Test case from https://gitlab.com/gitlab-org/gitlab-foss/issues/39227
        "Equifax branch name",
        "refs/heads/Equifax".encode("UTF-8"),
        "refs/heads/Equifax".encode("UTF-8")
      ]
    ].each do |description, test_string, xpect|
      it description do
        r = ext_class.encode_utf8(test_string)
        expect(r).to eq(xpect)
        expect(r.encoding.name).to eq('UTF-8') if xpect
      end
    end

    it 'returns empty string on conversion errors' do
      expect { ext_class.encode_utf8('') }.not_to raise_error
    end

    it 'replaces invalid and undefined chars with the replace argument' do
      str = 'hællo'.encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)

      expect(ext_class.encode_utf8(str, replace: "\u{FFFD}")).to eq("h�llo")
    end

    context 'with strings that can be forcefully encoded into utf8' do
      let(:test_string) do
        "refs/heads/FixSymbolsTitleDropdown".encode("ASCII-8BIT")
      end

      let(:expected_string) do
        "refs/heads/FixSymbolsTitleDropdown".encode("UTF-8")
      end

      subject { ext_class.encode_utf8(test_string) }

      it "doesn't use CharlockHolmes if the encoding can be forced into utf_8" do
        expect(CharlockHolmes::EncodingDetector).not_to receive(:detect)

        expect(subject).to eq(expected_string)
        expect(subject.encoding.name).to eq('UTF-8')
      end
    end
  end

  describe '#clean' do
    [
      [
        'leaves ascii only string as is',
        'ascii only string',
        'ascii only string'
      ],
      [
        'leaves valid utf8 string as is',
        'multibyte string №∑∉',
        'multibyte string №∑∉'
      ],
      [
        'removes invalid bytes from ASCII-8bit encoded multibyte string.',
        (+"Lorem ipsum\xC3\n dolor sit amet, xy\xC3\xA0y\xC3\xB9abcd\xC3\xB9efg").force_encoding('ASCII-8BIT'),
        "Lorem ipsum\n dolor sit amet, xyàyùabcdùefg"
      ],
      [
        'handles UTF-16BE encoded strings',
        (+"\xFE\xFF\x00\x41").force_encoding('ASCII-8BIT'), # An "A" prepended with UTF-16 BOM
        "\xEF\xBB\xBFA" # An "A" prepended with UTF-8 BOM
      ]
    ].each do |description, test_string, xpect|
      it description do
        expect(ext_class.encode!(test_string)).to eq(xpect)
      end
    end
  end

  describe 'encode_binary' do
    [
      [nil, ""],
      ["", ""],
      ["  ", "  "],
      %w[a1 a1],
      ["编码", "\xE7\xBC\x96\xE7\xA0\x81".b]
    ].each do |input, result|
      it "encodes #{input.inspect} to #{result.inspect}" do
        expect(ext_class.encode_binary(input)).to eq(result)
      end
    end
  end

  describe '#binary_io' do
    it 'does not mutate the original string encoding' do
      test = 'my-test'

      io_stream = ext_class.binary_io(test)

      expect(io_stream.external_encoding.name).to eq('ASCII-8BIT')
      expect(test.encoding.name).to eq('UTF-8')
    end

    it 'returns a copy of the IO with the correct encoding' do
      test = fixture_file_upload('spec/fixtures/doc_sample.txt').to_io

      io_stream = ext_class.binary_io(test)

      expect(io_stream.external_encoding.name).to eq('ASCII-8BIT')
      expect(test).not_to eq(io_stream)
    end
  end

  describe '#detect_encoding' do
    subject { ext_class.detect_encoding(data, **kwargs) }

    let(:data) { binary_string }
    let(:kwargs) { {} }

    context 'detects encoding' do
      it { is_expected.to be_a(Hash) }

      it 'correctly detects the binary' do
        expect(subject[:type]).to eq(:binary)
      end

      context 'data is nil' do
        let(:data) { nil }

        it { is_expected.to be_nil }
      end

      context 'limit is provided' do
        let(:kwargs) do
          { limit: 10 }
        end

        it 'correctly detects the binary' do
          expect(subject[:type]).to eq(:binary)
        end
      end
    end
  end

  describe '#unquote_path' do
    it do
      expect(described_class.unquote_path('unquoted')).to eq('unquoted')
      expect(described_class.unquote_path('"quoted"')).to eq('quoted')
      expect(described_class.unquote_path('"\\311\\240\\304\\253\\305\\247\\305\\200\\310\\247\\306\\200"')).to eq('ɠīŧŀȧƀ')
      expect(described_class.unquote_path('"\\\\303\\\\251"')).to eq('\303\251')
      expect(described_class.unquote_path('"\a\b\e\f\n\r\t\v\""')).to eq("\a\b\e\f\n\r\t\v\"")
    end
  end

  describe '#strip_bom' do
    it do
      expect(described_class.strip_bom('no changes')).to eq('no changes')
      expect(described_class.strip_bom("\xEF\xBB\xBFhello world")).to eq('hello world')
      expect(described_class.strip_bom("BOM at the end\xEF\xBB\xBF")).to eq("BOM at the end\xEF\xBB\xBF")
    end
  end

  # This cop's alternative to .dup doesn't work in this context for some reason.
  # rubocop: disable Performance/UnfreezeString
  describe "#force_encode_utf8" do
    let(:stringish) do
      Class.new(String) do
        undef :force_encoding
      end
    end

    it "raises an ArgumentError if the argument can't force encoding" do
      expect { described_class.force_encode_utf8(stringish.new("foo")) }.to raise_error(ArgumentError)
    end

    it "returns the message if already UTF-8 and valid encoding" do
      string = "føø".dup

      expect(string).not_to receive(:force_encoding).and_call_original
      expect(described_class.force_encode_utf8(string)).to eq("føø")
    end

    it "forcibly encodes a string to UTF-8" do
      string = "føø".dup.force_encoding("ISO-8859-1")

      expect(string).to receive(:force_encoding).with("UTF-8").and_call_original
      expect(described_class.force_encode_utf8(string)).to eq("føø")
    end

    it "forcibly encodes a frozen string to UTF-8" do
      string = "bår".dup.force_encoding("ISO-8859-1").freeze

      expect(described_class.force_encode_utf8(string)).to eq("bår")
    end
  end
  # rubocop: enable Performance/UnfreezeString
end
