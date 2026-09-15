# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Gpg::Commit, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :small_repo, path: 'sample-project') }

  let(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }
  let(:committer_email) { GpgHelpers::User1.emails.first }
  let(:user_email) { committer_email }
  let(:public_key) { GpgHelpers::User1.public_key }
  let(:user) { create(:user, email: user_email) }
  let(:commit) { create(:commit, project: project, sha: commit_sha, committer_email: committer_email) }
  let(:crypto) { instance_double(GPGME::Crypto) }
  let(:signer) { :SIGNER_USER }
  let(:mock_signature_data?) { true }
  # gpg_keys must be pre-loaded so that they can be found during signature verification.
  let!(:gpg_key) { create(:gpg_key, key: public_key, user: user) }

  let(:signature_data) do
    {
      signature: GpgHelpers::User1.signed_commit_signature,
      signed_text: GpgHelpers::User1.signed_commit_base_data,
      signer: signer,
      author_email: user_email,
      committer_email: user_email
    }
  end

  before do
    if mock_signature_data?
      allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
        .with(Gitlab::Git::Repository, commit_sha)
        .and_return(signature_data)
    end
  end

  describe '#signature' do
    shared_examples 'returns the cached signature on second call' do
      it 'returns the cached signature on second call' do
        gpg_commit = described_class.new(commit)

        gpg_commit.signature

        expect(Gitlab::Gpg).not_to receive(:using_tmp_keychain)

        gpg_commit.signature
      end
    end

    context 'unsigned commit' do
      let(:signature_data) { nil }

      it 'returns nil' do
        expect(described_class.new(commit).signature).to be_nil
      end
    end

    context 'invalid signature' do
      let(:signature_data) do
        {
          # Corrupt the key
          signature: GpgHelpers::User1.signed_commit_signature.tr('=', 'a'),
          signed_text: GpgHelpers::User1.signed_commit_base_data,
          signer: signer
        }
      end

      it 'returns nil' do
        expect(described_class.new(commit).signature).to be_nil
      end
    end

    context 'known key' do
      context 'user matches the key uid' do
        context 'user email matches the email committer' do
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
          before do
            verified_signature = double('verified-signature', fingerprint: GpgHelpers::User1.fingerprint, valid?: true)
            allow(GPGME::Crypto).to receive(:new).and_return(crypto)
            allow(crypto).to receive(:verify).and_yield(verified_signature)
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
          end
        end

        context 'valid key signed using older version of Gnupg' do
          before do
            keyid = GpgHelpers::User1.fingerprint.last(16)
            verified_signature = double('verified-signature', fingerprint: keyid, valid?: true)
            allow(GPGME::Crypto).to receive(:new).and_return(crypto)
            allow(crypto).to receive(:verify).and_yield(verified_signature)
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
          end
        end

        context 'commit with multiple signatures' do
          before do
            verified_signature = double('verified-signature', fingerprint: GpgHelpers::User1.fingerprint, valid?: true)
            allow(GPGME::Crypto).to receive(:new).and_return(crypto)
            allow(crypto).to receive(:verify).and_yield(verified_signature).and_yield(verified_signature)
          end

          it 'returns an invalid signatures error' do
            signature = described_class.new(commit).signature

            expect(signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'multiple_signatures'
            )
          end
        end

        context 'commit signed with a subkey' do
          let(:committer_email) { GpgHelpers::User3.emails.first }
          let(:public_key) { GpgHelpers::User3.public_key }

          let(:gpg_key_subkey) do
            gpg_key.subkeys.find_by(fingerprint: GpgHelpers::User3.subkey_fingerprints.last)
          end

          let(:signature_data) do
            {
              signature: GpgHelpers::User3.signed_commit_signature,
              signed_text: GpgHelpers::User3.signed_commit_base_data,
              signer: signer
            }
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

        context 'gpg key email does not match the committer_email but is the same user when the committer_email belongs to the user as a confirmed secondary email' do
          let(:committer_email) { GpgHelpers::User2.emails.first }

          let(:user) do
            create(:user, email: GpgHelpers::User1.emails.first).tap do |user|
              create :email, :confirmed, user: user, email: committer_email
            end
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

        context 'gpg key email does not match the committer_email when the committer_email belongs to the user as a unconfirmed secondary email' do
          let(:committer_email) { GpgHelpers::User2.emails.first }

          let(:user) do
            create(:user, email: GpgHelpers::User1.emails.first).tap do |user|
              create :email, user: user, email: committer_email
            end
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

        context 'user email does not match the committer email' do
          let(:committer_email) { GpgHelpers::User2.emails.first }
          let(:user_email) { GpgHelpers::User1.emails.first }

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

        context 'signing key has been revoked' do
          before do
            revoked_signature = instance_double(GPGME::Signature, fingerprint: GpgHelpers::User1.fingerprint,
              valid?: false, revoked_key?: true)
            allow(GPGME::Crypto).to receive(:new).and_return(crypto)
            allow(crypto).to receive(:verify).and_yield(revoked_signature)
          end

          it 'returns a revoked_key signature' do
            expect(described_class.new(commit).signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'revoked_key'
            )
          end

          it_behaves_like 'returns the cached signature on second call'
        end

        context 'signing key has expired' do
          before do
            expired_key_signature = instance_double(GPGME::Signature, fingerprint: GpgHelpers::User1.fingerprint,
              valid?: false, revoked_key?: false, expired_key?: true)
            allow(GPGME::Crypto).to receive(:new).and_return(crypto)
            allow(crypto).to receive(:verify).and_yield(expired_key_signature)
          end

          it 'returns an expired_key signature' do
            expect(described_class.new(commit).signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'expired_key'
            )
          end

          it_behaves_like 'returns the cached signature on second call'
        end

        context 'signature is invalid but key is neither revoked nor expired' do
          before do
            invalid_signature = instance_double(GPGME::Signature, fingerprint: GpgHelpers::User1.fingerprint,
              valid?: false, revoked_key?: false, expired_key?: false)
            allow(GPGME::Crypto).to receive(:new).and_return(crypto)
            allow(crypto).to receive(:verify).and_yield(invalid_signature)
          end

          it 'returns an unverified signature' do
            expect(described_class.new(commit).signature).to have_attributes(
              commit_sha: commit_sha,
              project: project,
              gpg_key: gpg_key,
              gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
              gpg_key_user_name: GpgHelpers::User1.names.first,
              gpg_key_user_email: GpgHelpers::User1.emails.first,
              verification_status: 'unverified'
            )
          end

          it_behaves_like 'returns the cached signature on second call'
        end
      end

      context 'user does not match the key uid' do
        let(:user_email) { GpgHelpers::User2.emails.first }
        let(:public_key) { GpgHelpers::User1.public_key }

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
      let(:gpg_key) { nil }

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

    context 'multiple commits with signatures' do
      let(:mock_signature_data?) { false }

      let!(:first_signature) { create(:gpg_signature) }
      let!(:gpg_key) { create(:gpg_key, key: GpgHelpers::User2.public_key) }
      let!(:second_signature) { create(:gpg_signature, gpg_key: gpg_key) }
      let!(:first_commit) { create(:commit, project: project, sha: first_signature.commit_sha) }
      let!(:second_commit) { create(:commit, project: project, sha: second_signature.commit_sha) }

      let!(:commits) do
        [first_commit, second_commit].map do |commit|
          gpg_commit = described_class.new(commit)

          allow(gpg_commit).to receive(:has_signature?).and_return(true)

          gpg_commit
        end
      end

      it 'does an aggregated sql request instead of 2 separate ones' do
        recorder = ActiveRecord::QueryRecorder.new do
          commits.each(&:signature)
        end

        expect(recorder.count).to eq(1)
      end
    end

    context 'when signature created by GitLab' do
      let(:signer) { :SIGNER_SYSTEM }
      let(:gpg_key) { nil }

      it 'returns a valid signature' do
        expect(described_class.new(commit).signature).to have_attributes(
          commit_sha: commit_sha,
          project: project,
          gpg_key: nil,
          gpg_key_primary_keyid: GpgHelpers::User1.primary_keyid,
          gpg_key_user_name: nil,
          gpg_key_user_email: nil,
          verification_status: 'verified_system',
          committer_email: user_email
        )
      end

      it_behaves_like 'returns the cached signature on second call'
    end
  end

  describe '#update_signature!' do
    let!(:gpg_key) { nil }

    let(:signature) { described_class.new(commit).signature }

    it 'updates signature record' do
      signature

      create(:gpg_key, key: public_key, user: user)

      stored_signature = CommitSignatures::GpgSignature.find_by_commit_sha(commit_sha)
      expect { described_class.new(commit).update_signature!(stored_signature) }.to(
        change { signature.reload.verification_status }.from('unknown_key').to('verified')
      )
    end

    context 'when signature is system verified and committer_email is nil' do
      let(:signer) { :SIGNER_SYSTEM }

      it 'update gpg_key_user_email with signature_data author_email' do
        signature

        stored_signature = CommitSignatures::GpgSignature.find_by_commit_sha(commit_sha)
        stored_signature.update!(committer_email: nil)

        expect { described_class.new(commit).update_signature!(stored_signature) }.to(
          change { signature.reload.committer_email }.from(nil).to(user_email)
        )
      end
    end
  end

  describe '#lazy_signature' do
    let(:mock_signature_data?) { false }
    let!(:gpg_key) { nil }

    let_it_be(:shared_gpg_key) { create(:gpg_key) }
    let_it_be(:project1) { create(:project, :small_repo) }
    let_it_be(:project2) { create(:project, :small_repo) }
    let_it_be(:commit1) { create(:commit, project: project1, sha: '1234567890abcdef1234567890abcdef12345678') }
    let_it_be(:commit2) { create(:commit, project: project1, sha: 'abcdef1234567890abcdef1234567890abcdef12') }
    let_it_be(:commit3) { create(:commit, project: project2, sha: 'fedcba0987654321fedcba0987654321fedcba09') }

    let_it_be(:signature1) do
      create(:gpg_signature, project: project1, commit_sha: commit1.sha, gpg_key: shared_gpg_key,
        verification_status: :verified)
    end

    let_it_be(:signature2) do
      create(:gpg_signature, project: project1, commit_sha: commit2.sha, gpg_key: shared_gpg_key,
        verification_status: :verified)
    end

    let_it_be(:signature3) do
      create(:gpg_signature, project: project2, commit_sha: commit3.sha, gpg_key: shared_gpg_key,
        verification_status: :verified)
    end

    before do
      allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily).and_return(nil)
    end

    it 'batches signature loading by project_id and commit_sha pairs' do
      gpg_commit1 = described_class.new(commit1)
      gpg_commit2 = described_class.new(commit2)
      gpg_commit3 = described_class.new(commit3)

      expect(CommitSignatures::GpgSignature).to receive(:by_commit_shas_and_project_ids).once.and_call_original

      sig1 = gpg_commit1.send(:lazy_signature).itself
      sig2 = gpg_commit2.send(:lazy_signature).itself
      sig3 = gpg_commit3.send(:lazy_signature).itself

      expect(sig1).to eq(signature1)
      expect(sig1.project_id).to eq(project1.id)
      expect(sig1.commit_sha).to eq(commit1.sha)

      expect(sig2).to eq(signature2)
      expect(sig2.project_id).to eq(project1.id)
      expect(sig2.commit_sha).to eq(commit2.sha)

      expect(sig3).to eq(signature3)
      expect(sig3.project_id).to eq(project2.id)
      expect(sig3.commit_sha).to eq(commit3.sha)
    end

    it 'correctly maps signatures to commits with same commit_sha in different projects' do
      same_sha = '1111111111111111111111111111111111111111'
      commit_proj1 = create(:commit, project: project1, sha: same_sha)
      commit_proj2 = create(:commit, project: project2, sha: same_sha)
      sig_proj1 = create(:gpg_signature, project: project1, commit_sha: same_sha, gpg_key: shared_gpg_key)
      sig_proj2 = create(:gpg_signature, project: project2, commit_sha: same_sha, gpg_key: shared_gpg_key)

      gpg_commit1 = described_class.new(commit_proj1)
      gpg_commit2 = described_class.new(commit_proj2)

      loaded_sig1 = gpg_commit1.send(:lazy_signature).itself
      loaded_sig2 = gpg_commit2.send(:lazy_signature).itself

      expect(loaded_sig1).to eq(sig_proj1)
      expect(loaded_sig1.project_id).to eq(project1.id)

      expect(loaded_sig2).to eq(sig_proj2)
      expect(loaded_sig2.project_id).to eq(project2.id)

      expect(loaded_sig1).not_to eq(loaded_sig2)
      expect(loaded_sig1.commit_sha).to eq(loaded_sig2.commit_sha)
    end

    it 'returns nil when no signature exists for a commit' do
      commit_without_sig = create(:commit, project: project1, sha: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
      gpg_commit = described_class.new(commit_without_sig)

      expect(gpg_commit.send(:lazy_signature).itself).to be_nil
    end
  end
end
