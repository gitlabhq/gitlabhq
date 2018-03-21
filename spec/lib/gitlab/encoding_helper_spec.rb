require "spec_helper"

describe Gitlab::EncodingHelper do
  let(:ext_class) { Class.new { extend Gitlab::EncodingHelper } }
  let(:binary_string) { File.read(Rails.root + "spec/fixtures/dk.png") }

  describe '#encode!' do
    [
      ["nil", nil, nil],
      ["empty string", "".encode("ASCII-8BIT"), "".encode("UTF-8")],
      ["invalid utf-8 encoded string", "my bad string\xE5".force_encoding("UTF-8"), "my bad string"],
      ["frozen non-ascii string", "é".force_encoding("ASCII-8BIT").freeze, "é".encode("UTF-8")],
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
        "mu ns\xC3\n Lorem ipsum dolor sit amet, consectetur adipisicing ut\xC3\xA0y\xC3\xB9abcd\xC3\xB9efg kia elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non p\n {: .normal_pn}\n \n-Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in\n# *Lorem ipsum\xC3\xB9l\xC3\xB9l\xC3\xA0 dolor\xC3\xB9k\xC3\xB9 sit\xC3\xA8b\xC3\xA8 N\xC3\xA8 amet b\xC3\xA0d\xC3\xAC*\n+# *consectetur\xC3\xB9l\xC3\xB9l\xC3\xA0 adipisicing\xC3\xB9k\xC3\xB9 elit\xC3\xA8b\xC3\xA8 N\xC3\xA8 sed do\xC3\xA0d\xC3\xAC*{: .italic .smcaps}\n \n \xEF\x9B\xA1 eiusmod tempor incididunt, ut\xC3\xAAn\xC3\xB9 labore et dolore. Tw\xC4\x83nj\xC3\xAC magna aliqua. Ut enim ad minim veniam\n {: .normal}\n@@ -9,5 +9,5 @@ quis nostrud\xC3\xAAt\xC3\xB9 exercitiation ullamco laboris m\xC3\xB9s\xC3\xB9k\xC3\xB9abc\xC3\xB9 nisi ".force_encoding('ASCII-8BIT'),
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
      let(:corrupted_diff) do
        with_empty_bare_repository do |repo|
          content = File.read(Rails.root.join(
            'spec/fixtures/encoding/Japanese.md').to_s)
          commit_a = commit(repo, 'Japanese.md', content)
          commit_b = commit(repo, 'Japanese.md',
            content.sub('[TODO: Link]', '[現在作業中です: Link]'))

          repo.diff(commit_a, commit_b).each_line.map(&:content).join
        end
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

      def commit(repo, path, content)
        oid = repo.write(content, :blob)
        index = repo.index

        index.read_tree(repo.head.target.tree) unless repo.empty?

        index.add(path: path, oid: oid, mode: 0100644)
        user = { name: 'Test', email: 'test@example.com' }

        Rugged::Commit.create(
          repo,
          tree: index.write_tree(repo),
          author: user,
          committer: user,
          message: "Update #{path}",
          parents: repo.empty? ? [] : [repo.head.target].compact,
          update_ref: 'HEAD'
        )
      end
    end
  end

  describe '#encode_utf8' do
    [
      ["nil", nil, nil],
      ["empty string", "".encode("ASCII-8BIT"), "".encode("UTF-8")],
      ["invalid utf-8 encoded string", "my bad string\xE5".force_encoding("UTF-8"), "my bad stringå"],
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
        # Test case from https://gitlab.com/gitlab-org/gitlab-ce/issues/39227
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
      expect { ext_class.encode_utf8('') }.not_to raise_error(ArgumentError)
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
        "Lorem ipsum\xC3\n dolor sit amet, xy\xC3\xA0y\xC3\xB9abcd\xC3\xB9efg".force_encoding('ASCII-8BIT'),
        "Lorem ipsum\n dolor sit amet, xyàyùabcdùefg"
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
      %w(a1 a1),
      ["编码", "\xE7\xBC\x96\xE7\xA0\x81".b]
    ].each do |input, result|
      it "encodes #{input.inspect} to #{result.inspect}" do
        expect(ext_class.encode_binary(input)).to eq(result)
      end
    end
  end
end
