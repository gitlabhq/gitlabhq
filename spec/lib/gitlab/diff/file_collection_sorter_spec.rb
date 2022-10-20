# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Diff::FileCollectionSorter do
  let(:diffs) do
    [
      double(new_path: 'README', old_path: 'README'),
      double(new_path: '.dir/test', old_path: '.dir/test'),
      double(new_path: '', old_path: '.file'),
      double(new_path: '1-folder/A-file.ext', old_path: '1-folder/A-file.ext'),
      double(new_path: '1-folder/README', old_path: '1-folder/README'),
      double(new_path: nil, old_path: '1-folder/M-file.ext'),
      double(new_path: '1-folder/Z-file.ext', old_path: '1-folder/Z-file.ext'),
      double(new_path: '1-folder/README', old_path: '1-folder/README'),
      double(new_path: '', old_path: '1-folder/nested/A-file.ext'),
      double(new_path: '1-folder/nested/M-file.ext', old_path: '1-folder/nested/M-file.ext'),
      double(new_path: nil, old_path: '1-folder/nested/Z-file.ext'),
      double(new_path: '2-folder/A-file.ext', old_path: '2-folder/A-file.ext'),
      double(new_path: '', old_path: '2-folder/M-file.ext'),
      double(new_path: '2-folder/Z-file.ext', old_path: '2-folder/Z-file.ext'),
      double(new_path: nil, old_path: '2-folder/nested/A-file.ext'),
      double(new_path: 'A-file.ext', old_path: 'A-file.ext'),
      double(new_path: '', old_path: 'M-file.ext'),
      double(new_path: 'Z-file.ext', old_path: 'Z-file.ext'),
      double(new_path: 'README', old_path: 'README')
    ]
  end

  subject { described_class.new(diffs) }

  describe '#sort' do
    let(:sorted_files_paths) { subject.sort.map { |file| file.new_path.presence || file.old_path } }

    it 'returns list sorted directory first' do
      expect(sorted_files_paths).to eq(
        [
          '.dir/test',
          '1-folder/nested/A-file.ext',
          '1-folder/nested/M-file.ext',
          '1-folder/nested/Z-file.ext',
          '1-folder/A-file.ext',
          '1-folder/M-file.ext',
          '1-folder/README',
          '1-folder/README',
          '1-folder/Z-file.ext',
          '2-folder/nested/A-file.ext',
          '2-folder/A-file.ext',
          '2-folder/M-file.ext',
          '2-folder/Z-file.ext',
          '.file',
          'A-file.ext',
          'M-file.ext',
          'README',
          'README',
          'Z-file.ext'
        ])
    end
  end
end
