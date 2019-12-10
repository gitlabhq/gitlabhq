require 'rails_helper'

describe Gitlab::Gpg::Commit do
  describe '#signature' do
    shared_examples 'returns the cached signature on second call' do
      it 'returns the cached signature on second call' do
        gpg_commit = described_class.new(commit)

        expect(gpg_commit).to receive(:using_keychain).and_call_original
        gpg_commit.signature

        # consecutive call
        expect(gpg_commit).not_to receive(:using_keychain).and_call_original
        gpg_commit.signature
      end
    end

    let!(:project) { create :project, :repository, path: 'sample-project' }
    let!(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }

    context 'unsigned commit' do
      let!(:commit) { create :commit, project: project, sha: commit_sha }

      it 'returns nil' do
        expect(described_class.new(commit).signature).to be_nil
      end
    end

    context 'invalid signature' do
      let!(:commit) { create :commit, project: project, sha: commit_sha, committer_email: GpgHelpers::User1.emails.first }

      let!(:user) { create(:user, email: GpgHelpers::User1.emails.first) }

      before do
        allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
            .with(Gitlab::Git::Repository, commit_sha)
            .and_return(
              [
                # Corrupt the key
                GpgHelpers::User1.signed_commit_signature.tr('=', 'a'),
                GpgHelpers::User1.signed_commit_base_data
              ]
            )
      end

      it 'returns nil' do
        expect(described_class.new(commit).signature).to be_nil
      end
    end

    context 'known key' do
      context 'user matches the key uid' do
        context 'user email matches the email committer' do
          let!(:commit) { create :commit, project: project, sha: commit_sha, committer_email: GpgHelpers::User1.emails.first }

          let!(:user) { create(:user, email: GpgHelpers::User1.emails.first) }

          let!(:gpg_key) do
            create :gpg_key, key: GpgHelpers::User1.public_key, user: user
          end

          before do
            allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
            .with(Gitlab::Git::Repository, commit_sha)
            .and_return(
              [
                GpgHelpers::User1.signed_commit_signature,
                GpgHelpers::User1.signed_commit_base_data
              ]
            )
          end

          it 'returns a valid signature' do
            signature = described_class.new(commit).signature

            expect(signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'verified'
            )
            expect(signature.persisted?).to be_truthy
          end

          it_behaves_like 'returns the cached signature on second call'

          context 'read-only mode' do
            before do
              allow(Gitlab::Database).to receive(:read_only?).and_return(true)
            end

            it 'does not create a cached signature' do
              signature = described_class.new(commit).signature

              expect(signature).to have_attributes(
                commit_sha: commit_sha,
                project: project,
                gpg_key: gpg_key,
                gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
                gpg_key_user_name: GpgHelpers::User1.names.first,
                gpg_key_user_email: GpgHelpers::User1.emails.first,
                verification_status: 'verified'
              )
              expect(signature.persisted?).to be_falsey
            end
          end
        end

        context 'valid key signed using recent version of Gnupg' do
          let!(:commit) { create :commit, project: project, sha: commit_sha, committer_email: GpgHelpers::User1.emails.first }

          let!(:user) { create(:user, email: GpgHelpers::User1.emails.first) }

          let!(:gpg_key) do
            create :gpg_key, key: GpgHelpers::User1.public_key, user: user
          end

          let!(:crypto) { instance_double(GPGME::Crypto) }

          before do
            fake_signature = [
              GpgHelpers::User1.signed_commit_signature,
              GpgHelpers::User1.signed_commit_base_data
            ]

            allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
              .with(Gitlab::Git::Repository, commit_sha)
              .and_return(fake_signature)
          end

          it 'returns a valid signature' do
            verified_signature = double('verified-signature', fingerprint: GpgHelpers::User1.fingerprint, valid?: true)
            allow(GPGME::Crypto).to receive(:new).and_return(crypto)
            allow(crypto).to receive(:verify).and_return(verified_signature)

            signature = described_class.new(commit).signature

            expect(signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'verified'
            )
          end
        end

        context 'valid key signed using older version of Gnupg' do
          let!(:commit) { create :commit, project: project, sha: commit_sha, committer_email: GpgHelpers::User1.emails.first }

          let!(:user) { create(:user, email: GpgHelpers::User1.emails.first) }

          let!(:gpg_key) do
            create :gpg_key, key: GpgHelpers::User1.public_key, user: user
          end

          let!(:crypto) { instance_double(GPGME::Crypto) }

          before do
            fake_signature = [
              GpgHelpers::User1.signed_commit_signature,
              GpgHelpers::User1.signed_commit_base_data
            ]

            allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
              .with(Gitlab::Git::Repository, commit_sha)
              .and_return(fake_signature)
          end

          it 'returns a valid signature' do
            keyid = GpgHelpers::User1.fingerprint.last(16)
            verified_signature = double('verified-signature', fingerprint: keyid, valid?: true)
            allow(GPGME::Crypto).to receive(:new).and_return(crypto)
            allow(crypto).to receive(:verify).and_return(verified_signature)

            signature = described_class.new(commit).signature

            expect(signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'verified'
            )
          end
        end

        context 'commit signed with a subkey' do
          let!(:commit) { create :commit, project: project, sha: commit_sha, committer_email: GpgHelpers::User3.emails.first }

          let!(:user) { create(:user, email: GpgHelpers::User3.emails.first) }

          let!(:gpg_key) do
            create :gpg_key, key: GpgHelpers::User3.public_key, user: user
          end

          let(:gpg_key_subkey) do
            gpg_key.subkeys.find_by(fingerprint: GpgHelpers::User3.subkey_fingerprints.last)
          end

          before do
            allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
            .with(Gitlab::Git::Repository, commit_sha)
            .and_return(
              [
                GpgHelpers::User3.signed_commit_signature,
                GpgHelpers::User3.signed_commit_base_data
              ]
            )
          end

          it 'returns a valid signature' do
            expect(described_class.new(commit).signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key_subkey,
              gpg_key_primary_keyid: gpg_key_subkey.keyid,
              gpg_key_user_name: GpgHelpers::User3.names.first,
              gpg_key_user_email: GpgHelpers::User3.emails.first,
              verification_status: 'verified'
            )
          end

          it_behaves_like 'returns the cached signature on second call'
        end

        context 'user email does not match the committer email, but is the same user' do
          let!(:commit) { create :commit, project: project, sha: commit_sha, committer_email: GpgHelpers::User2.emails.first }

          let(:user) do
            create(:user, email: GpgHelpers::User1.emails.first).tap do |user|
              create :email, user: user, email: GpgHelpers::User2.emails.first
            end
          end

          let!(:gpg_key) do
            create :gpg_key, key: GpgHelpers::User1.public_key, user: user
          end

          before do
            allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
            .with(Gitlab::Git::Repository, commit_sha)
            .and_return(
              [
                GpgHelpers::User1.signed_commit_signature,
                GpgHelpers::User1.signed_commit_base_data
              ]
            )
          end

          it 'returns an invalid signature' do
            expect(described_class.new(commit).signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'same_user_different_email'
            )
          end

          it_behaves_like 'returns the cached signature on second call'
        end

        context 'user email does not match the committer email' do
          let!(:commit) { create :commit, project: project, sha: commit_sha, committer_email: GpgHelpers::User2.emails.first }

          let(:user) { create(:user, email: GpgHelpers::User1.emails.first) }

          let!(:gpg_key) do
            create :gpg_key, key: GpgHelpers::User1.public_key, user: user
          end

          before do
            allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
            .with(Gitlab::Git::Repository, commit_sha)
            .and_return(
              [
                GpgHelpers::User1.signed_commit_signature,
                GpgHelpers::User1.signed_commit_base_data
              ]
            )
          end

          it 'returns an invalid signature' do
            expect(described_class.new(commit).signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'other_user'
            )
          end

          it_behaves_like 'returns the cached signature on second call'
        end
      end

      context 'user does not match the key uid' do
        let!(:commit) { create :commit, project: project, sha: commit_sha }

        let(:user) { create(:user, email: GpgHelpers::User2.emails.first) }

        let!(:gpg_key) do
          create :gpg_key, key: GpgHelpers::User1.public_key, user: user
        end

        before do
          allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
          .with(Gitlab::Git::Repository, commit_sha)
          .and_return(
            [
              GpgHelpers::User1.signed_commit_signature,
              GpgHelpers::User1.signed_commit_base_data
            ]
          )
        end

        it 'returns an invalid signature' do
          expect(described_class.new(commit).signature).to have_attributes(
            commit_sha: commit_sha,
            project: project,
            gpg_key: gpg_key,
            gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
            gpg_key_user_name: GpgHelpers::User1.names.first,
            gpg_key_user_email: GpgHelpers::User1.emails.first,
            verification_status: 'unverified_key'
          )
        end

        it_behaves_like 'returns the cached signature on second call'
      end
    end

    context 'unknown key' do
      let!(:commit) { create :commit, project: project, sha: commit_sha }

      before do
        allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
          .with(Gitlab::Git::Repository, commit_sha)
          .and_return(
            [
              GpgHelpers::User1.signed_commit_signature,
              GpgHelpers::User1.signed_commit_base_data
            ]
          )
      end

      it 'returns an invalid signature' do
        expect(described_class.new(commit).signature).to have_attributes(
          commit_sha: commit_sha,
          project: project,
          gpg_key: nil,
          gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
          gpg_key_user_name: nil,
          gpg_key_user_email: nil,
          verification_status: 'unknown_key'
        )
      end

      it_behaves_like 'returns the cached signature on second call'
    end
  end
end
