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

  describe '#lazy_signature' do
    let_it_be(:project1) { create(:project, :repository) }
    let_it_be(:project2) { create(:project, :repository) }
    let_it_be(:commit1) { create(:commit, project: project1, sha: '1234567890abcdef1234567890abcdef12345678') }
    let_it_be(:commit2) { create(:commit, project: project1, sha: 'abcdef1234567890abcdef1234567890abcdef12') }
    let_it_be(:commit3) { create(:commit, project: project2, sha: 'fedcba0987654321fedcba0987654321fedcba09') }
    let_it_be(:commit4) { create(:commit, project: project2, sha: '1234567890abcdef1234567890abcdef12345678') }

    let_it_be(:signature1) do
      create(
        :ssh_signature,
        project: project1,
        commit_sha: commit1.sha,
        verification_status: :verified
      )
    end

    let_it_be(:signature2) do
      create(
        :ssh_signature,
        project: project1,
        commit_sha: commit2.sha,
        verification_status: :verified
      )
    end

    let_it_be(:signature3) do
      create(
        :ssh_signature,
        project: project2,
        commit_sha: commit3.sha,
        verification_status: :verified
      )
    end

    before do
      allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily).and_return(nil)
    end

    it 'batches signature loading by project_id and commit_sha pairs' do
      ssh_commit1 = described_class.new(commit1)
      ssh_commit2 = described_class.new(commit2)
      ssh_commit3 = described_class.new(commit3)

      # Expect a single batched query for all signatures
      expect(CommitSignatures::SshSignature).to receive(:by_commit_shas_and_project_ids).once.and_call_original

      sig1 = ssh_commit1.send(:lazy_signature).itself
      sig2 = ssh_commit2.send(:lazy_signature).itself
      sig3 = ssh_commit3.send(:lazy_signature).itself

      # Verify each commit gets its correct signature
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
      sig_proj1 = create(:ssh_signature, project: project1, commit_sha: same_sha)
      sig_proj2 = create(:ssh_signature, project: project2, commit_sha: same_sha)

      ssh_commit1 = described_class.new(commit_proj1)
      ssh_commit2 = described_class.new(commit_proj2)

      loaded_sig1 = ssh_commit1.send(:lazy_signature).itself
      loaded_sig2 = ssh_commit2.send(:lazy_signature).itself

      # Each commit should get its own project's signature, not the other's
      expect(loaded_sig1).to eq(sig_proj1)
      expect(loaded_sig1.project_id).to eq(project1.id)

      expect(loaded_sig2).to eq(sig_proj2)
      expect(loaded_sig2.project_id).to eq(project2.id)

      # Verify they're different signatures
      expect(loaded_sig1).not_to eq(loaded_sig2)
      expect(loaded_sig1.commit_sha).to eq(loaded_sig2.commit_sha)
    end

    it 'returns nil when no signature exists for a commit' do
      commit_without_sig = create(:commit, project: project1, sha: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
      ssh_commit = described_class.new(commit_without_sig)

      expect(ssh_commit.send(:lazy_signature).itself).to be_nil
    end
  end
end
