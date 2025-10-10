# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Ssh::Commit, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:signed_by_key) { create(:key) }
  let_it_be(:fingerprint) { signed_by_key.fingerprint_sha256 }

  let(:commit) { create(:commit, project: project) }
  let(:signature_text) { 'signature_text' }
  let(:signed_text) { 'signed_text' }
  let(:signer) { :SIGNER_USER }
  let(:user_committer) { create(:user) }
  let(:committer_email) { user_committer.email }
  let(:signature_data) do
    { signature: signature_text, signed_text: signed_text, signer: signer, committer_email: committer_email }
  end

  let(:verifier) { instance_double('Gitlab::Ssh::Signature') }
  let(:verification_status) { :verified }

  subject(:signature) { described_class.new(commit).signature }

  before do
    allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
      .with(Gitlab::Git::Repository, commit.sha)
      .and_return(signature_data)

    allow_next_instance_of(Commit) do |instance|
      allow(instance).to receive(:committer_email).and_return(user_committer.email)
    end

    allow(verifier).to receive_messages({
      verification_status: verification_status,
      signed_by_key: signed_by_key,
      key_fingerprint: fingerprint
    })

    allow(verifier).to receive(:user_id).and_return(user_committer.id)

    allow(Gitlab::Ssh::Signature).to receive(:new)
      .with(signature_text, signed_text, signer, commit)
      .and_return(verifier)
  end

  describe '#signature' do
    it 'returns the cached signature on multiple calls' do
      ssh_commit = described_class.new(commit)

      expect(ssh_commit).to receive(:create_cached_signature!).and_call_original
      ssh_commit.signature

      expect(ssh_commit).not_to receive(:create_cached_signature!)
      ssh_commit.signature
    end

    context 'when all expected data is present' do
      it 'calls signature verifier and uses returned attributes' do
        expect(signature).to have_attributes(
          commit_sha: commit.sha,
          project: project,
          key_id: signed_by_key.id,
          key_fingerprint_sha256: signed_by_key.fingerprint_sha256,
          user_id: user_committer.id,
          verification_status: 'verified'
        )
      end
    end

    context 'when signed_by_key is nil' do
      let_it_be(:signed_by_key) { nil }
      let_it_be(:fingerprint) { nil }

      let(:verification_status) { :unknown_key }

      it 'creates signature without a key_id' do
        expect(signature).to have_attributes(
          commit_sha: commit.sha,
          project: project,
          key_id: nil,
          key_fingerprint_sha256: nil,
          user_id: user_committer.id,
          verification_status: 'unknown_key'
        )
      end
    end

    context 'when signature is verified_system' do
      before do
        allow(verifier).to receive_messages(
          verification_status: :verified_system,
          user_id: user.id
        )
      end

      let(:user) { create(:user) }
      let(:signer) { :VERIFIED_SYSTEM }

      it 'returns the correct attributes' do
        expect(signature).to have_attributes(
          commit_sha: commit.sha,
          user_id: user.id,
          verification_status: 'verified_system',
          committer_email: committer_email
        )
      end

      context 'when a stored signature is present for the commit with committer_email nil' do
        let(:signature_with_no_committer_email) do
          create(:ssh_signature,
            commit_sha: commit.sha,
            verification_status: :verified_system,
            user_id: nil,
            project: project,
            key_fingerprint_sha256: fingerprint,
            key_id: signed_by_key.id,
            committer_email: nil
          )
        end

        before do
          allow(CommitSignatures::SshSignature)
            .to receive(:by_commit_sha)
                  .with([commit.id])
                  .and_return([signature_with_no_committer_email])
        end

        context 'when committer_email is present' do
          it 'updates stored signature with committer_email only' do
            ActiveRecord.verbose_query_logs = true
            expect(signature.committer_email).to eq(user_committer.email)
          end
        end

        context 'when signature committer_email is not present' do
          let(:committer_email) { nil }

          it 'does not update the stored signature' do
            expect(signature).not_to receive(:update!)
          end
        end

        context 'when feature flag check_for_mailmapped_commit_emails is disabled' do
          before do
            stub_feature_flags(check_for_mailmapped_commit_emails: false)
          end

          it 'does not update the stored signature' do
            expect(signature.committer_email).to be_nil
          end
        end
      end
    end
  end

  describe '#update_signature!' do
    it 'updates verification status' do
      allow(verifier).to receive(:verification_status).and_return(:unverified)
      signature

      stored_signature = CommitSignatures::SshSignature.find_by_commit_sha(commit.sha)

      allow(verifier).to receive(:verification_status).and_return(:verified)

      expect { described_class.new(commit).update_signature!(stored_signature) }.to(
        change { signature.reload.verification_status }.from('unverified').to('verified')
      )
    end
  end
end
