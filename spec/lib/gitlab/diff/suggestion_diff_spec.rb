# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Diff::SuggestionDiff do
  describe '#diff_lines' do
    let(:from_content) do
      <<-BLOB.strip_heredoc
         "tags": ["devel", "development", "nightly"],
         "desktop-file-name-prefix": "(Development) ",
         "finish-args": "foo",
      BLOB
    end

    let(:to_content) do
      <<-BLOB.strip_heredoc
         "buildsystem": "meson",
         "builddir": true,
         "name": "nautilus",
         "bar": "bar",
      BLOB
    end

    let(:suggestion) do
      instance_double(Suggestion, from_line: 12,
                                  from_content: from_content,
                                  to_content: to_content)
    end

    subject { described_class.new(suggestion).diff_lines }

    let(:expected_diff_lines) do
      [
        { old_pos: 12, new_pos: 12, type: "match", text: "@@ -12 +12" },
        { old_pos: 12, new_pos: 12, type: "old", text: "-\"tags\": [\"devel\", \"development\", \"nightly\"]," },
        { old_pos: 13, new_pos: 12, type: "old", text: "-\"desktop-file-name-prefix\": \"(Development) \"," },
        { old_pos: 14, new_pos: 12, type: "old", text: "-\"finish-args\": \"foo\"," },
        { old_pos: 15, new_pos: 12, type: "new", text: "+\"buildsystem\": \"meson\"," },
        { old_pos: 15, new_pos: 13, type: "new", text: "+\"builddir\": true," },
        { old_pos: 15, new_pos: 14, type: "new", text: "+\"name\": \"nautilus\"," },
        { old_pos: 15, new_pos: 15, type: "new", text: "+\"bar\": \"bar\"," }
      ]
    end

    it 'returns diff lines with correct line numbers' do
      diff_lines = subject

      expect(diff_lines).to all(be_a(Gitlab::Diff::Line))

      expected_diff_lines.each_with_index do |expected_line, index|
        expect(diff_lines[index].to_hash).to include(expected_line)
      end
    end
  end
end
