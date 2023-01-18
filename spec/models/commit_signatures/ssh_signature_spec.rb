# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignatures::SshSignature, feature_category: :source_code_management do
  # This commit is seeded from https://gitlab.com/gitlab-org/gitlab-test
  # For instructions on how to add more seed data, see the project README
  let_it_be(:commit_sha) { '7b5160f9bb23a3d58a0accdbe89da13b96b1ece9' }
  let_it_be(:project) { create(:project, :repository, path: 'sample-project') }
  let_it_be(:commit) { create(:commit, project: project, sha: commit_sha) }
  let_it_be(:ssh_key) { create(:ed25519_key_256) }
  let_it_be(:user) { ssh_key.user }
  let_it_be(:key_fingerprint) { ssh_key.fingerprint_sha256 }

  let(:signature) do
    create(:ssh_signature, commit_sha: commit_sha, key: ssh_key, key_fingerprint_sha256: key_fingerprint, user: user)
  end

  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      key: ssh_key,
      key_fingerprint_sha256: key_fingerprint,
      user: user
    }
  end

  it_behaves_like 'having unique enum values'
  it_behaves_like 'commit signature'
  it_behaves_like 'signature with type checking', :ssh

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

  describe '#key_fingerprint_sha256' do
    it 'returns the fingerprint_sha256 associated with the SSH key' do
      expect(signature.key_fingerprint_sha256).to eq(key_fingerprint)
    end

    context 'when the SSH key is no longer associated with the signature' do
      it 'returns the fingerprint_sha256 stored in signature' do
        signature.update!(key_id: nil)

        expect(signature.key_fingerprint_sha256).to eq(key_fingerprint)
      end
    end
  end

  describe '#signed_by_user' do
    it 'returns the user associated with the SSH key' do
      expect(signature.signed_by_user).to eq(ssh_key.user)
    end

    context 'when the SSH key is no longer associated with the signature' do
      it 'returns the user stored in signature' do
        signature.update!(key_id: nil)

        expect(signature.signed_by_user).to eq(user)
      end
    end
  end
end
