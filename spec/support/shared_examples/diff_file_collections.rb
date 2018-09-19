# frozen_string_literal: true

shared_examples 'diff statistics' do |test_include_stats_flag: true|
  def stub_stats_find_by_path(path, stats_mock)
    expect_next_instance_of(Gitlab::Git::DiffStatsCollection) do |collection|
      allow(collection).to receive(:find_by_path).and_call_original
      expect(collection).to receive(:find_by_path).with(path).and_return(stats_mock)
    end
  end

  context 'when should request diff stats' do
    it 'Repository#diff_stats is called' do
      subject = described_class.new(diffable, collection_default_args)

      expect(diffable.project.repository)
        .to receive(:diff_stats)
        .with(diffable.diff_refs.base_sha, diffable.diff_refs.head_sha)
        .and_call_original

      subject.diff_files
    end

    it 'Gitlab::Diff::File is initialized with diff stats' do
      subject = described_class.new(diffable, collection_default_args)

      stats_mock = double(Gitaly::DiffStats, path: '.gitignore', additions: 758, deletions: 120)
      stub_stats_find_by_path(stub_path, stats_mock)

      diff_file = subject.diff_files.find { |file| file.new_path == stub_path }

      expect(diff_file.added_lines).to eq(stats_mock.additions)
      expect(diff_file.removed_lines).to eq(stats_mock.deletions)
    end
  end

  context 'when should not request diff stats' do
    it 'Repository#diff_stats is not called' do
      collection_default_args[:diff_options][:include_stats] = false

      subject = described_class.new(diffable, collection_default_args)

      expect(diffable.project.repository).not_to receive(:diff_stats)

      subject.diff_files
    end
  end
end
