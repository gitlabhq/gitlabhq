require 'rails_helper'

RSpec.describe Gitlab::Gpg::Commit do
  describe '#signature' do
    let!(:project) { create :project, :repository, path: 'sample-project' }
    let!(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33'  }

    context 'unisgned commit' do
      it 'returns nil' do
        expect(described_class.new(project.commit).signature).to be_nil
      end
    end

    context 'known and verified public key' do
      let!(:gpg_key) do
        create :gpg_key, key: GpgHelpers::User1.public_key, user: create(:user, email: GpgHelpers::User1.emails.first)
      end

      let!(:commit) do
        raw_commit = double(:raw_commit, signature: [
          GpgHelpers::User1.signed_commit_signature,
          GpgHelpers::User1.signed_commit_base_data
        ], sha: commit_sha)
        allow(raw_commit).to receive :save!

        create :commit, git_commit: raw_commit, project: project
      end

      it 'returns a valid signature' do
        expect(described_class.new(commit).signature).to have_attributes(
          commit_sha: commit_sha,
          project: project,
          gpg_key: gpg_key,
          gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
          gpg_key_user_name: GpgHelpers::User1.names.first,
          gpg_key_user_email: GpgHelpers::User1.emails.first,
          valid_signature: true
        )
      end

      it 'returns the cached signature on second call' do
        gpg_commit = described_class.new(commit)

        expect(gpg_commit).to receive(:using_keychain).and_call_original
        gpg_commit.signature

        # consecutive call
        expect(gpg_commit).not_to receive(:using_keychain).and_call_original
        gpg_commit.signature
      end
    end

    context 'known but unverified public key' do
      let!(:gpg_key) { create :gpg_key, key: GpgHelpers::User1.public_key }

      let!(:commit) do
        raw_commit = double(:raw_commit, signature: [
          GpgHelpers::User1.signed_commit_signature,
          GpgHelpers::User1.signed_commit_base_data
        ], sha: commit_sha)
        allow(raw_commit).to receive :save!

        create :commit, git_commit: raw_commit, project: project
      end

      it 'returns an invalid signature' do
        expect(described_class.new(commit).signature).to have_attributes(
          commit_sha: commit_sha,
          project: project,
          gpg_key: gpg_key,
          gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
          gpg_key_user_name: GpgHelpers::User1.names.first,
          gpg_key_user_email: GpgHelpers::User1.emails.first,
          valid_signature: false
        )
      end

      it 'returns the cached signature on second call' do
        gpg_commit = described_class.new(commit)

        expect(gpg_commit).to receive(:using_keychain).and_call_original
        gpg_commit.signature

        # consecutive call
        expect(gpg_commit).not_to receive(:using_keychain).and_call_original
        gpg_commit.signature
      end
    end

    context 'unknown public key' do
      let!(:commit) do
        raw_commit = double(:raw_commit, signature: [
          GpgHelpers::User1.signed_commit_signature,
          GpgHelpers::User1.signed_commit_base_data
        ], sha: commit_sha)
        allow(raw_commit).to receive :save!

        create :commit,
          git_commit: raw_commit,
          project: project
      end

      it 'returns an invalid signature' do
        expect(described_class.new(commit).signature).to have_attributes(
          commit_sha: commit_sha,
          project: project,
          gpg_key: nil,
          gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
          gpg_key_user_name: nil,
          gpg_key_user_email: nil,
          valid_signature: false
        )
      end

      it 'returns the cached signature on second call' do
        gpg_commit = described_class.new(commit)

        expect(gpg_commit).to receive(:using_keychain).and_call_original
        gpg_commit.signature

        # consecutive call
        expect(gpg_commit).not_to receive(:using_keychain).and_call_original
        gpg_commit.signature
      end
    end
  end
end
