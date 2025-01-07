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

      expect(subject.start_commit).to eq(nil)
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
  end

  describe '#commit' do
    it 'returns raw compare head commit' do
      expect(subject.commit.id).to eq(head_commit.id)
    end

    it 'returns nil if compare head commit is nil' do
      expect(raw_compare).to receive(:head).and_return(nil)

      expect(subject.commit).to eq(nil)
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

      expect(subject.base_commit_sha).to eq(nil)
    end

    it 'returns nil if there is no head commit' do
      expect(subject).to receive(:head_commit).and_return(nil)

      expect(subject.base_commit_sha).to eq(nil)
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
        is_expected.to eq(from: start_commit.id, to: head_commit.id)
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
end
