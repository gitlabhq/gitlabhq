# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/heading_slug'

RSpec.describe Gitlab::HeadingSlug, :aggregate_failures, feature_category: :markdown do
  describe '.from_text' do
    using RSpec::Parameterized::TableSyntax

    where(:text, :expected_slug, :case_name) do
      [
        ['path/to/my_file.rb', 'pathtomy_filerb', 'removes non-permitted characters'],
        ['(Tips & Tricks)', 'tips--tricks', 'converts spaces to dashes'],
        ['Café', 'café', 'preserves accented characters'],
        ['日本語の見出し', '日本語の見出し', 'preserves non-Latin text'],
        ['!#$%&*+,./:;=?@\^`|~<>[]{}()', '', 'returns empty string for all non-permitted characters']
      ]
    end

    with_them do
      it 'generates the expected slug' do
        expect(described_class.from_text(text)).to eq(expected_slug)
      end
    end
  end

  describe '.prefix_from_file_path' do
    using RSpec::Parameterized::TableSyntax

    where(:file_path, :expected_prefix, :case_name) do
      [
        ['README_ja.org', 'readme_ja-', 'preserves underscores in filename'],
        ['README.ja.org', 'readmeja-', 'strips only the last extension'],
        ['README', 'readme-', 'handles filenames without extension'],
        ['議事録.org', '議事録-', 'preserves non-Latin characters'],
        ['!#$%&*+,./:;=?@\^`|~<>[]{}().org', nil, 'returns nil when filename produces empty slug'],
        [nil, nil, 'returns nil when file_path is nil']
      ]
    end

    with_them do
      it 'returns the filename-based prefix' do
        expect(described_class.prefix_from_file_path(file_path)).to eq(expected_prefix)
      end
    end
  end
end
