# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContextCommitsDiff do
  let_it_be(:sha1) { "33f3729a45c02fc67d00adb1b8bca394b0e761d9" }
  let_it_be(:sha2) { "ae73cb07c9eeaf35924a10f713b364d32b2dd34f" }
  let_it_be(:sha3) { "0b4bc9a49b562e85de7cc9e834518ea6828729b9" }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }
  let_it_be(:mrcc1) { create(:merge_request_context_commit, merge_request: merge_request, sha: sha1, committed_date: project.commit_by(oid: sha1).committed_date) }
  let_it_be(:mrcc2) { create(:merge_request_context_commit, merge_request: merge_request, sha: sha2, committed_date: project.commit_by(oid: sha2).committed_date) }
  let_it_be(:mrcc3) { create(:merge_request_context_commit, merge_request: merge_request, sha: sha3, committed_date: project.commit_by(oid: sha3).committed_date) }

  subject { merge_request.context_commits_diff }

  describe ".empty?" do
    it 'checks if empty' do
      expect(subject.empty?).to be(false)
    end
  end

  describe '.commits_count' do
    it 'reports commits count' do
      expect(subject.commits_count).to be(3)
    end
  end

  describe '.diffs' do
    it 'returns instance of Gitlab::Diff::FileCollection::Compare' do
      expect(subject.diffs).to be_a(Gitlab::Diff::FileCollection::Compare)
    end

    it 'returns all diffs between first and last commits' do
      expect(subject.diffs.diff_files.size).to be(5)
    end
  end

  describe '.raw_diffs' do
    before do
      allow(subject).to receive(:paths).and_return(["Gemfile.zip", "files/images/6049019_460s.jpg", "files/ruby/feature.rb"])
    end

    it 'returns instance of Gitlab::Git::DiffCollection' do
      expect(subject.raw_diffs).to be_a(Gitlab::Git::DiffCollection)
    end

    it 'returns only diff for files changed in the context commits' do
      expect(subject.raw_diffs.size).to be(3)
    end
  end

  describe '.diff_refs' do
    it 'returns correct sha' do
      expect(subject.diff_refs.head_sha).to eq(sha3)
      expect(subject.diff_refs.base_sha).to eq("913c66a37b4a45b9769037c55c2d238bd0942d2e")
    end
  end
end
