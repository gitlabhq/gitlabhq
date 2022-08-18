# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Ssh::Commit do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:signed_by_key) { create(:key) }

  let(:commit) { create(:commit, project: project) }
  let(:signature_text) { 'signature_text' }
  let(:signed_text) { 'signed_text' }
  let(:signature_data) { [signature_text, signed_text] }
  let(:verifier) { instance_double('Gitlab::Ssh::Signature') }
  let(:verification_status) { :verified }

  subject(:signature) { described_class.new(commit).signature }

  before do
    allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
      .with(Gitlab::Git::Repository, commit.sha)
      .and_return(signature_data)

    allow(verifier).to receive(:verification_status).and_return(verification_status)
    allow(verifier).to receive(:signed_by_key).and_return(signed_by_key)

    allow(Gitlab::Ssh::Signature).to receive(:new)
      .with(signature_text, signed_text, commit.committer_email)
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
          verification_status: 'verified'
        )
      end
    end

    context 'when signed_by_key is nil' do
      let_it_be(:signed_by_key) { nil }

      let(:verification_status) { :unknown_key }

      it 'creates signature without a key_id' do
        expect(signature).to have_attributes(
          commit_sha: commit.sha,
          project: project,
          key_id: nil,
          verification_status: 'unknown_key'
        )
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
