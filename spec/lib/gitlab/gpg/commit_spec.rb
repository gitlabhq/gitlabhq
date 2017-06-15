require 'rails_helper'

RSpec.describe Gitlab::Gpg::Commit do
  describe '#signature' do
    let!(:project) { create :project, :repository, path: 'sample-project' }

    context 'unisgned commit' do
      it 'returns nil' do
        expect(described_class.new(project.commit).signature).to be_nil
      end
    end

    context 'known public key' do
      it 'returns a valid signature' do
        gpg_key = create :gpg_key, key: GpgHelpers::User1.public_key

        raw_commit = double(:raw_commit, signature: [
          GpgHelpers::User1.signed_commit_signature,
          GpgHelpers::User1.signed_commit_base_data
        ], sha: '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33')
        allow(raw_commit).to receive :save!

        commit = create :commit,
          git_commit: raw_commit,
          project: project

        expect(described_class.new(commit).signature).to have_attributes(
          commit_sha: '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33',
          project: project,
          gpg_key: gpg_key,
          gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
          valid_signature: true
        )
      end
    end

    context 'unknown public key' do
      it 'returns an invalid signature', :gpg do
        raw_commit = double(:raw_commit, signature: [
          GpgHelpers::User1.signed_commit_signature,
          GpgHelpers::User1.signed_commit_base_data
        ], sha: '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33')
        allow(raw_commit).to receive :save!

        commit = create :commit,
          git_commit: raw_commit,
          project: project

        expect(described_class.new(commit).signature).to have_attributes(
          commit_sha: '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33',
          project: project,
          gpg_key: nil,
          gpg_key_primary_keyid: nil,
          valid_signature: false
        )
      end
    end
  end
end
