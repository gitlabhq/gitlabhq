require 'rails_helper'

RSpec.describe Gitlab::Gpg::InvalidGpgSignatureUpdater do
  describe '#run' do
    let!(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }
    let!(:project) { create :project, :repository, path: 'sample-project' }
    let!(:commit) do
      raw_commit = double(:raw_commit, signature: [
        GpgHelpers::User1.signed_commit_signature,
        GpgHelpers::User1.signed_commit_base_data
      ], sha: commit_sha)
      allow(raw_commit).to receive :save!

      create :commit, git_commit: raw_commit, project: project
    end

    let!(:gpg_signature) do
      create :gpg_signature,
        project: project,
        commit_sha: commit_sha,
        gpg_key: nil,
        gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
        valid_signature: false
    end

    before do
      allow(Gitlab::Git::Commit).to receive(:find).with(kind_of(Repository), commit_sha).and_return(commit)
    end

    context 'gpg signature did not have an associated gpg key' do
      let!(:user) { create :user, email: GpgHelpers::User1.emails.first }

      it 'updates the signature to being valid when the missing gpg key is added' do
        # InvalidGpgSignatureUpdater is called by the after_create hook
        create :gpg_key,
          key: GpgHelpers::User1.public_key,
          user: user

        expect(gpg_signature.reload.valid_signature).to be_truthy
      end

      it 'keeps the signature at being invalid when an unrelated gpg key is added' do
        # InvalidGpgSignatureUpdater is called by the after_create hook
        create :gpg_key,
          key: GpgHelpers::User2.public_key,
          user: user

        expect(gpg_signature.reload.valid_signature).to be_falsey
      end
    end

    context 'gpg signature did have an associated unverified gpg key' do
      let!(:user) do
        create(:user, email: 'unrelated@example.com').tap do |user|
          user.skip_reconfirmation!
        end
      end

      it 'updates the signature to being valid when the user updates the email address' do
        create :gpg_key,
          key: GpgHelpers::User1.public_key,
          user: user

        expect(gpg_signature.reload.valid_signature).to be_falsey

        # InvalidGpgSignatureUpdater is called by the after_update hook
        user.update_attributes!(email: GpgHelpers::User1.emails.first)

        expect(gpg_signature.reload.valid_signature).to be_truthy
      end

      it 'keeps the signature at being invalid when the changed email address is still unrelated' do
        create :gpg_key,
          key: GpgHelpers::User1.public_key,
          user: user

        expect(gpg_signature.reload.valid_signature).to be_falsey

        # InvalidGpgSignatureUpdater is called by the after_update hook
        user.update_attributes!(email: 'still.unrelated@example.com')

        expect(gpg_signature.reload.valid_signature).to be_falsey
      end
    end
  end
end
