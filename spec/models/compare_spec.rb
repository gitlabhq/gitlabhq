require 'spec_helper'

describe Compare do
  include RepoHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:commit)  { project.commit }

  let(:start_commit) { sample_image_commit }
  let(:head_commit) { sample_commit }

  let(:raw_compare) { Gitlab::Git::Compare.new(project.repository.raw_repository, start_commit.id, head_commit.id) }

  subject { described_class.new(raw_compare, project) }

  describe '#start_commit' do
    it 'returns raw compare base commit' do
      expect(subject.start_commit.id).to eq(start_commit.id)
    end

    it 'returns nil if compare base commit is nil' do
      expect(raw_compare).to receive(:base).and_return(nil)

      expect(subject.start_commit).to eq(nil)
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

  describe '#base_commit' do
    let(:base_commit) { Commit.new(another_sample_commit, project) }

    it 'returns project merge base commit' do
      expect(project).to receive(:merge_base_commit).with(start_commit.id, head_commit.id).and_return(base_commit)

      expect(subject.base_commit).to eq(base_commit)
    end

    it 'returns nil if there is no start_commit' do
      expect(subject).to receive(:start_commit).and_return(nil)

      expect(subject.base_commit).to eq(nil)
    end

    it 'returns nil if there is no head commit' do
      expect(subject).to receive(:head_commit).and_return(nil)

      expect(subject.base_commit).to eq(nil)
    end
  end

  describe '#diff_refs' do
    it 'uses base_commit sha as base_sha' do
      expect(subject).to receive(:base_commit).at_least(:once).and_call_original

      expect(subject.diff_refs.base_sha).to eq(subject.base_commit.id)
    end

    it 'uses start_commit sha as start_sha' do
      expect(subject.diff_refs.start_sha).to eq(start_commit.id)
    end

    it 'uses commit sha as head sha' do
      expect(subject.diff_refs.head_sha).to eq(head_commit.id)
    end
  end
end
