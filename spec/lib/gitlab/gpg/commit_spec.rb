require 'rails_helper'

describe Gitlab::Gpg::Commit do
  describe '#signature' do
    let!(:project) { create :project, :repository, path: 'sample-project' }
    let!(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33'  }

    context 'unsigned commit' do
      it 'returns nil' do
        expect(described_class.new(project, commit_sha).signature).to be_nil
      end
    end

    context 'known and verified public key' do
      let!(:gpg_key) do
        create :gpg_key, key: GpgHelpers::User1.public_key, user: create(:user, email: GpgHelpers::User1.emails.first)
      end

      before do
        allow(Rugged::Commit).to receive(:extract_signature)
          .with(Rugged::Repository, commit_sha)
          .and_return(
            [
              GpgHelpers::User1.signed_commit_signature,
              GpgHelpers::User1.signed_commit_base_data
            ]
          )
      end

      it 'returns a valid signature' do
        expect(described_class.new(project, commit_sha).signature).to have_attributes(
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
        gpg_commit = described_class.new(project, commit_sha)

        expect(gpg_commit).to receive(:using_keychain).and_call_original
        gpg_commit.signature

        # consecutive call
        expect(gpg_commit).not_to receive(:using_keychain).and_call_original
        gpg_commit.signature
      end
    end

    context 'known but unverified public key' do
      let!(:gpg_key) { create :gpg_key, key: GpgHelpers::User1.public_key }

      before do
        allow(Rugged::Commit).to receive(:extract_signature)
          .with(Rugged::Repository, commit_sha)
          .and_return(
            [
              GpgHelpers::User1.signed_commit_signature,
              GpgHelpers::User1.signed_commit_base_data
            ]
          )
      end

      it 'returns an invalid signature' do
        expect(described_class.new(project, commit_sha).signature).to have_attributes(
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
        gpg_commit = described_class.new(project, commit_sha)

        expect(gpg_commit).to receive(:using_keychain).and_call_original
        gpg_commit.signature

        # consecutive call
        expect(gpg_commit).not_to receive(:using_keychain).and_call_original
        gpg_commit.signature
      end
    end

    context 'unknown public key' do
      before do
        allow(Rugged::Commit).to receive(:extract_signature)
          .with(Rugged::Repository, commit_sha)
          .and_return(
            [
              GpgHelpers::User1.signed_commit_signature,
              GpgHelpers::User1.signed_commit_base_data
            ]
          )
      end

      it 'returns an invalid signature' do
        expect(described_class.new(project, commit_sha).signature).to have_attributes(
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
        gpg_commit = described_class.new(project, commit_sha)

        expect(gpg_commit).to receive(:using_keychain).and_call_original
        gpg_commit.signature

        # consecutive call
        expect(gpg_commit).not_to receive(:using_keychain).and_call_original
        gpg_commit.signature
      end
    end
  end
end
