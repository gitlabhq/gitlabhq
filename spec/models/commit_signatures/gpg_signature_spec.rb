# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignatures::GpgSignature do
  # This commit is seeded from https://gitlab.com/gitlab-org/gitlab-test
  # For instructions on how to add more seed data, see the project README
  let_it_be(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }
  let_it_be(:project) { create(:project, :repository, path: 'sample-project') }
  let_it_be(:commit) { create(:commit, project: project, sha: commit_sha) }
  let_it_be(:gpg_key) { create(:gpg_key) }
  let_it_be(:gpg_key_subkey) { create(:gpg_key_subkey, gpg_key: gpg_key) }

  let(:signature) { create(:gpg_signature, commit_sha: commit_sha, gpg_key: gpg_key) }

  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      gpg_key_primary_keyid: gpg_key.keyid
    }
  end

  it_behaves_like 'having unique enum values'
  it_behaves_like 'commit signature'
  it_behaves_like 'signature with type checking', :gpg

  describe 'associations' do
    it { is_expected.to belong_to(:gpg_key) }
    it { is_expected.to belong_to(:gpg_key_subkey) }
  end

  describe 'validation' do
    subject { described_class.new }

    it { is_expected.to validate_presence_of(:commit_sha) }
    it { is_expected.to validate_presence_of(:gpg_key_primary_keyid) }
  end

  describe '.by_commit_sha scope' do
    let_it_be(:another_gpg_signature) { create(:gpg_signature, gpg_key: gpg_key) }

    it 'returns all gpg signatures by sha' do
      expect(described_class.by_commit_sha(commit_sha)).to match_array([signature])
      expect(
        described_class.by_commit_sha([commit_sha, another_gpg_signature.commit_sha])
      ).to contain_exactly(signature, another_gpg_signature)
    end
  end

  describe '#gpg_key=' do
    it 'supports the assignment of a GpgKey' do
      signature = create(:gpg_signature, gpg_key: gpg_key)

      expect(signature.gpg_key).to be_an_instance_of(GpgKey)
    end

    it 'supports the assignment of a GpgKeySubkey' do
      signature = create(:gpg_signature, gpg_key: gpg_key_subkey)

      expect(signature.gpg_key).to be_an_instance_of(GpgKeySubkey)
    end

    it 'clears gpg_key and gpg_key_subkey_id when passing nil' do
      signature.update_attribute(:gpg_key, nil)

      expect(signature.gpg_key_id).to be_nil
      expect(signature.gpg_key_subkey_id).to be_nil
    end
  end

  describe '#gpg_commit' do
    context 'when commit does not exist' do
      it 'returns nil' do
        allow(signature).to receive(:commit).and_return(nil)

        expect(signature.gpg_commit).to be_nil
      end
    end

    context 'when commit exists' do
      it 'returns an instance of Gitlab::Gpg::Commit' do
        allow(signature).to receive(:commit).and_return(commit)

        expect(signature.gpg_commit).to be_an_instance_of(Gitlab::Gpg::Commit)
      end
    end
  end

  describe '#signed_by_user' do
    it 'retrieves the gpg_key user' do
      expect(signature.signed_by_user).to eq(gpg_key.user)
    end
  end
end
