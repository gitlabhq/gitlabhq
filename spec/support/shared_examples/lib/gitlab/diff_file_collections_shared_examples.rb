# frozen_string_literal: true

RSpec.shared_examples 'diff statistics' do |test_include_stats_flag: true|
  subject { described_class.new(diffable, **collection_default_args) }

  def stub_stats_find_by_path(path, stats_mock)
    expect_next_instance_of(Gitlab::Git::DiffStatsCollection) do |collection|
      allow(collection).to receive(:find_by_path).and_call_original
      expect(collection).to receive(:find_by_path).with(path).and_return(stats_mock)
    end
  end

  context 'when include_stats is true' do
    it 'Repository#diff_stats is called' do
      expect(diffable.project.repository)
        .to receive(:diff_stats)
        .with(diffable.diff_refs.base_sha, diffable.diff_refs.head_sha)
        .and_call_original

      subject.diff_files
    end

    it 'Gitlab::Diff::File is initialized with diff stats' do
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

      expect(diffable.project.repository).not_to receive(:diff_stats)

      subject.diff_files
    end
  end
end

RSpec.shared_examples 'unfoldable diff' do
  let(:subject) { described_class.new(diffable, diff_options: nil) }

  it 'calls Gitlab::Diff::File#unfold_diff_lines with correct position' do
    position = instance_double(Gitlab::Diff::Position, file_path: 'README')
    readme_file = instance_double(Gitlab::Diff::File, file_path: 'README')
    other_file = instance_double(Gitlab::Diff::File, file_path: 'foo.rb')
    nil_path_file = instance_double(Gitlab::Diff::File, file_path: nil)

    allow(subject).to receive(:diff_files) { [readme_file, other_file, nil_path_file] }
    expect(readme_file).to receive(:unfold_diff_lines).with(position)

    subject.unfold_diff_files([position])
  end
end

RSpec.shared_examples 'cacheable diff collection' do
  let(:highlight_cache) { instance_double(Gitlab::Diff::HighlightCache, write_if_empty: true, clear: nil, decorate: nil) }
  let(:stats_cache) { instance_double(Gitlab::Diff::StatsCache, read: nil, write_if_empty: true, clear: nil) }

  before do
    expect(Gitlab::Diff::HighlightCache).to receive(:new).with(subject) { highlight_cache }
  end

  describe '#write_cache' do
    before do
      expect(Gitlab::Diff::StatsCache).to receive(:new).with(cachable_key: diffable.cache_key) { stats_cache }
    end

    it 'calls Gitlab::Diff::HighlightCache#write_if_empty' do
      expect(highlight_cache).to receive(:write_if_empty).once

      subject.write_cache
    end

    it 'calls Gitlab::Diff::StatsCache#write_if_empty with diff stats' do
      diff_stats = Gitlab::Git::DiffStatsCollection.new([])

      expect(diffable.project.repository)
        .to receive(:diff_stats).and_return(diff_stats)

      expect(stats_cache).to receive(:write_if_empty).once.with(diff_stats)

      subject.write_cache
    end
  end

  describe '#clear_cache' do
    before do
      expect(Gitlab::Diff::StatsCache).to receive(:new).with(cachable_key: diffable.cache_key) { stats_cache }
    end

    it 'calls Gitlab::Diff::HighlightCache#clear' do
      expect(highlight_cache).to receive(:clear).once

      subject.clear_cache
    end

    it 'calls Gitlab::Diff::StatsCache#clear' do
      expect(stats_cache).to receive(:clear).once

      subject.clear_cache
    end
  end

  describe '#diff_files' do
    before do
      expect(Gitlab::Diff::StatsCache).to receive(:new).with(cachable_key: diffable.cache_key) { stats_cache }
    end

    it 'calls Gitlab::Diff::HighlightCache#decorate' do
      expect(highlight_cache).to receive(:decorate)
        .with(instance_of(Gitlab::Diff::File))
        .exactly(cacheable_files_count).times

      subject.diff_files
    end

    context 'when there are stats cached' do
      before do
        allow(stats_cache).to receive(:read).and_return(Gitlab::Git::DiffStatsCollection.new([]))
      end

      it 'does not make a diff stats rpc call' do
        expect(diffable.project.repository).not_to receive(:diff_stats)

        subject.diff_files
      end
    end

    context 'when there are no stats cached' do
      it 'makes a diff stats rpc call' do
        expect(diffable.project.repository)
          .to receive(:diff_stats)
          .with(diffable.diff_refs.base_sha, diffable.diff_refs.head_sha)

        subject.diff_files
      end
    end
  end
end

shared_examples_for 'sortable diff files' do
  subject { described_class.new(diffable, **collection_default_args) }

  describe '#raw_diff_files' do
    let(:raw_diff_files_paths) do
      subject.raw_diff_files(sorted: sorted).map { |file| file.new_path.presence || file.old_path }
    end

    context 'when sorted is false (default)' do
      let(:sorted) { false }

      it 'returns unsorted diff files' do
        expect(raw_diff_files_paths).to eq(unsorted_diff_files_paths)
      end
    end

    context 'when sorted is true' do
      let(:sorted) { true }

      it 'returns sorted diff files' do
        expect(raw_diff_files_paths).to eq(sorted_diff_files_paths)
      end
    end
  end
end

shared_examples_for 'unsortable diff files' do
  subject { described_class.new(diffable, **collection_default_args) }

  describe '#raw_diff_files' do
    it 'does not call Gitlab::Diff::FileCollectionSorter even when sorted is true' do
      # Ensure that diffable is created before expectation to ensure that we are
      # not calling it from `FileCollectionSorter` from `#raw_diff_files`.
      diffable

      expect(Gitlab::Diff::FileCollectionSorter).not_to receive(:new)

      subject.raw_diff_files(sorted: true)
    end
  end
end
