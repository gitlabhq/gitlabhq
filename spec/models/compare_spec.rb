# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Compare, feature_category: :source_code_management do
  include RepoHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:commit)  { project.commit }

  let(:start_commit) { sample_image_commit }
  let(:head_commit) { sample_commit }
  let(:straight) { false }

  let(:raw_compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, start_commit.id, head_commit.id) }

  subject(:compare) { described_class.new(raw_compare, project, straight: straight) }

  describe '#cache_key' do
    subject { compare.cache_key }

    it { is_expected.to include(project) }
    it { is_expected.to include(:compare) }
    it { is_expected.to include(compare.diff_refs.hash) }
  end

  describe '#start_commit' do
    it 'returns raw compare base commit' do
      expect(subject.start_commit.id).to eq(start_commit.id)
    end

    it 'returns nil if compare base commit is nil' do
      expect(raw_compare).to receive(:base).and_return(nil)

      expect(subject.start_commit).to be_nil
    end
  end

  describe '#raw_diffs' do
    let(:base_sha) { nil }
    let(:diff_options) { { ignore_whitespace_change: true } }
    let(:compare) { described_class.new(raw_compare, project, base_sha: base_sha, straight: straight) }

    subject(:raw_diffs) { compare.raw_diffs(diff_options) }

    context 'when base_sha is provided' do
      let(:base_sha) { start_commit.id }

      it 'passes the provided base SHA as the merge base with the caller options' do
        expect(raw_compare).to receive(:diffs)
          .with(diff_options.merge(merge_base: base_sha))

        raw_diffs
      end
    end

    context 'when a merge base is computed' do
      it 'passes the computed base SHA as the merge base' do
        expect(raw_compare).to receive(:diffs)
          .with(diff_options.merge(merge_base: project.repository.merge_base(start_commit.id, head_commit.id)))

        raw_diffs
      end
    end

    context 'when there is no merge base' do
      before do
        allow(project).to receive(:merge_base_commit).and_return(nil)
      end

      it 'passes the start SHA as the merge base' do
        expect(raw_compare).to receive(:diffs)
          .with(diff_options.merge(merge_base: start_commit.id))

        raw_diffs
      end
    end

    context 'when neither a merge base nor a usable start SHA is available' do
      let(:diff_refs) do
        instance_double(Gitlab::Diff::DiffRefs, base_sha: nil, start_sha: '')
      end

      before do
        allow(compare).to receive(:diff_refs).and_return(diff_refs)
      end

      it 'passes the caller options without a merge base' do
        expect(raw_compare).to receive(:diffs).with({ ignore_whitespace_change: true })

        raw_diffs
      end
    end

    context 'when the comparison is straight' do
      let(:straight) { true }

      it 'does not compute or pass a merge base', :aggregate_failures do
        expect(compare).not_to receive(:diff_refs)
        expect(raw_compare).to receive(:diffs).with(diff_options)

        raw_diffs
      end
    end
  end

  describe '#commits' do
    subject { compare.commits }

    it 'returns a CommitCollection' do
      is_expected.to be_kind_of(CommitCollection)
    end

    it 'returns a list of commits' do
      commit_ids = subject.map(&:id)

      expect(commit_ids).to include(head_commit.id)
      expect(commit_ids.length).to eq(6)
    end

    context 'with limit parameter' do
      it 'passes the limit through to the raw compare and does not cache the result', :aggregate_failures do
        expect(raw_compare).to receive(:commits).with(limit: 2).twice.and_call_original

        result1 = compare.commits(limit: 2)
        result2 = compare.commits(limit: 2)

        expect(result1).to be_kind_of(CommitCollection)
        expect(result1.count).to eq(2)
        expect(result2).to be_kind_of(CommitCollection)
      end
    end
  end

  describe '#commit' do
    it 'returns raw compare head commit' do
      expect(subject.commit.id).to eq(head_commit.id)
    end

    it 'returns nil if compare head commit is nil' do
      expect(raw_compare).to receive(:head).and_return(nil)

      expect(subject.commit).to be_nil
    end
  end

  describe '#base_commit_sha' do
    it 'returns @base_sha if it is present' do
      expect(project).not_to receive(:merge_base_commit)

      sha = double
      service = described_class.new(raw_compare, project, base_sha: sha)

      expect(service.base_commit_sha).to eq(sha)
    end

    it 'fetches merge base SHA from repo when @base_sha is nil' do
      expect(project).to receive(:merge_base_commit)
        .with(start_commit.id, head_commit.id)
        .once
        .and_call_original

      expect(subject.base_commit_sha)
        .to eq(project.repository.merge_base(start_commit.id, head_commit.id))
    end

    it 'is memoized on first call' do
      expect(project).to receive(:merge_base_commit)
        .with(start_commit.id, head_commit.id)
        .once
        .and_call_original

      3.times { subject.base_commit_sha }
    end

    it 'returns nil if there is no start_commit' do
      expect(subject).to receive(:start_commit).and_return(nil)

      expect(subject.base_commit_sha).to be_nil
    end

    it 'returns nil if there is no head commit' do
      expect(subject).to receive(:head_commit).and_return(nil)

      expect(subject.base_commit_sha).to be_nil
    end
  end

  describe '#diff_refs' do
    it 'uses base_commit_sha sha as base_sha' do
      expect(subject.diff_refs.base_sha).to eq(subject.base_commit_sha)
    end

    it 'uses start_commit sha as start_sha' do
      expect(subject.diff_refs.start_sha).to eq(start_commit.id)
    end

    it 'uses commit sha as head sha' do
      expect(subject.diff_refs.head_sha).to eq(head_commit.id)
    end

    context 'when there is no merge base' do
      let(:start_commit) { project.commit(TestEnv::BRANCH_SHA['master']) }
      let(:head_commit) { project.commit(TestEnv::BRANCH_SHA['orphaned-branch']) }

      it 'uses the start commit as the base', :aggregate_failures do
        expect(compare.base_commit_sha).to be_nil
        expect(compare.diff_refs.base_sha).to eq(start_commit.id)
        expect(compare.diff_refs.start_sha).to eq(start_commit.id)
        expect(compare.diff_refs.head_sha).to eq(head_commit.id)
      end

      context 'when the comparison is straight' do
        let(:straight) { true }

        it 'uses the start commit as the base without computing a merge base', :aggregate_failures do
          expect(project).not_to receive(:merge_base_commit)

          expect(compare.diff_refs.base_sha).to eq(start_commit.id)
          expect(compare.diff_refs.start_sha).to eq(start_commit.id)
          expect(compare.diff_refs.head_sha).to eq(head_commit.id)
        end
      end
    end
  end

  describe '#diff_stats' do
    it 'returns diff stats' do
      stats = subject.diff_stats

      expect(stats).to be_a(Gitlab::Git::DiffStatsCollection)
      expect(stats.count).to be > 0
    end

    it 'calls repository.diff_stats with correct parameters' do
      expect(project.repository).to receive(:diff_stats).with(subject.diff_refs.base_sha,
        subject.diff_refs.head_sha).and_call_original

      subject.diff_stats
    end

    it 'returns nil when diff_refs is nil' do
      allow(subject).to receive(:diff_refs).and_return(nil)

      expect(subject.diff_stats).to be_nil
    end

    context 'when there is no merge base' do
      let(:start_commit) { project.commit(TestEnv::BRANCH_SHA['master']) }
      let(:head_commit) { project.commit(TestEnv::BRANCH_SHA['orphaned-branch']) }

      it 'returns stats for changes from the start commit', :aggregate_failures do
        expect(compare.base_commit_sha).to be_nil
        expect(compare.diff_stats.count).to eq(43)
      end
    end
  end

  describe '#changed_paths' do
    subject(:changed_paths) { compare.changed_paths }

    context 'changes are present' do
      let(:raw_compare) do
        Gitlab::Git::Compare.new(
          project.repository.raw_repository, 'before-create-delete-modify-move', 'after-create-delete-modify-move'
        )
      end

      it 'returns affected file paths' do
        is_expected.to all(be_a(Gitlab::Git::ChangedPath))

        expect(changed_paths.map { |a| [a.old_path, a.path, a.status] }).to match_array(
          [
            ['foo/for_move.txt', 'foo/bar/for_move.txt', :RENAMED],
            ['foo/for_create.txt', 'foo/for_create.txt', :ADDED],
            ['foo/for_delete.txt', 'foo/for_delete.txt', :DELETED],
            ['foo/for_edit.txt', 'foo/for_edit.txt', :MODIFIED]
          ]
        )
      end
    end

    context 'changes are absent' do
      let(:start_commit) { sample_commit }
      let(:head_commit) { sample_commit }

      it { is_expected.to eq([]) }
    end

    context 'when there is no merge base between commits' do
      let(:expected_paths_and_statuses) do
        [
          ['.DS_Store', :DELETED],
          ['.gitignore', :MODIFIED],
          ['.gitmodules', :MODIFIED],
          ['Gemfile.zip', :ADDED],
          ['files/.DS_Store', :DELETED],
          ['files/ruby/popen.rb', :MODIFIED],
          ['files/ruby/regex.rb', :MODIFIED],
          ['files/ruby/version_info.rb', :MODIFIED],
          ['gitlab-shell', :ADDED]
        ]
      end

      before do
        allow(project).to receive(:merge_base_commit).and_return(nil)
      end

      it 'returns paths changed between the start and head commits' do
        expect(changed_paths.map { |path| [path.path, path.status] }).to match_array(expected_paths_and_statuses)
      end

      it 'returns detailed diffs between the start and head commits' do
        detailed_paths_and_statuses = compare.diffs.diff_files.map do |diff_file|
          changed_path = Gitlab::Git::ChangedPath.from_diff(diff_file)

          [changed_path.path, changed_path.status]
        end

        expect(detailed_paths_and_statuses).to match_array(expected_paths_and_statuses)
      end
    end
  end

  describe '#modified_paths' do
    context 'changes are present' do
      let(:raw_compare) do
        Gitlab::Git::Compare.new(
          project.repository.raw_repository, 'before-create-delete-modify-move', 'after-create-delete-modify-move'
        )
      end

      it 'returns affected file paths, without duplication' do
        expect(subject.modified_paths).to contain_exactly(
          *%w[
            foo/for_move.txt
            foo/bar/for_move.txt
            foo/for_create.txt
            foo/for_delete.txt
            foo/for_edit.txt
          ])
      end
    end

    context 'changes are absent' do
      let(:start_commit) { sample_commit }
      let(:head_commit) { sample_commit }

      it 'returns empty array' do
        expect(subject.modified_paths).to eq([])
      end
    end
  end

  describe '#to_param' do
    subject { compare.to_param }

    let(:start_commit) { another_sample_commit }
    let(:base_commit) { head_commit }

    it 'returns the range between base and head commits' do
      is_expected.to eq(from: base_commit.id, to: head_commit.id)
    end

    context 'when straight mode is on' do
      let(:straight) { true }

      it 'returns the range between start and head commits' do
        is_expected.to eq(from: start_commit.id, to: head_commit.id, straight: true)
      end
    end

    context 'when there are no merge base between commits' do
      before do
        allow(project).to receive(:merge_base_commit).and_return(nil)
      end

      it 'returns the range between start and head commits' do
        is_expected.to eq(from: start_commit.id, to: head_commit.id)
      end
    end
  end

  describe '#diffs_for_streaming' do
    it 'returns a diff file collection commit' do
      expect(compare.diffs_for_streaming).to be_a_kind_of(Gitlab::Diff::FileCollection::Compare)
    end

    it_behaves_like 'diffs for streaming' do
      let(:repository) { project.repository }
      let(:resource) { compare }
    end
  end

  describe '#first_diffs_slice' do
    let(:limit) { 5 }

    subject(:first_diffs_slice) { compare.first_diffs_slice(limit) }

    it 'returns limited diffs' do
      expect(first_diffs_slice.count).to eq(limit)
    end

    it 'passes the correct options to diffs' do
      expect(compare).to receive(:diffs).with(hash_including(max_files: limit)).and_call_original

      first_diffs_slice
    end
  end
end
