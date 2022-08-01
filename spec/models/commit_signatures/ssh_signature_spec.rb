# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignatures::SshSignature do
  # This commit is seeded from https://gitlab.com/gitlab-org/gitlab-test
  # For instructions on how to add more seed data, see the project README
  let(:commit_sha) { '7b5160f9bb23a3d58a0accdbe89da13b96b1ece9' }
  let!(:project) { create(:project, :repository, path: 'sample-project') }
  let!(:commit) { create(:commit, project: project, sha: commit_sha) }
  let(:signature) { create(:ssh_signature, commit_sha: commit_sha) }
  let(:ssh_key) { create(:ed25519_key_256) }
  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      key: ssh_key
    }
  end

  it_behaves_like 'having unique enum values'
  it_behaves_like 'commit signature'

  describe 'associations' do
    it { is_expected.to belong_to(:key).optional }
  end

  describe '.by_commit_sha scope' do
    let!(:another_signature) { create(:ssh_signature, commit_sha: '0000000000000000000000000000000000000001') }

    it 'returns all signatures by sha' do
      expect(described_class.by_commit_sha(commit_sha)).to match_array([signature])
      expect(
        described_class.by_commit_sha([commit_sha, another_signature.commit_sha])
      ).to contain_exactly(signature, another_signature)
    end
  end
end
