# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignatures::SshSignature, feature_category: :source_code_management do
  # This commit is seeded from https://gitlab.com/gitlab-org/gitlab-test
  # For instructions on how to add more seed data, see the project README
  let_it_be(:commit_sha) { '7b5160f9bb23a3d58a0accdbe89da13b96b1ece9' }
  let_it_be(:project) { create(:project, :repository, path: 'sample-project') }
  let_it_be(:user) { create(:user) }
  let_it_be(:commit) { create(:commit, project: project, sha: commit_sha) }
  let_it_be(:ssh_key) { create(:ed25519_key_256, user: user) }
  let_it_be(:key_fingerprint) { ssh_key.fingerprint_sha256 }

  let(:verification_status) { :verified }

  let(:signature) do
    create(:ssh_signature, commit_sha: commit_sha, key: ssh_key, key_fingerprint_sha256: key_fingerprint, user: user,
      verification_status: verification_status)
  end

  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      key: ssh_key,
      key_fingerprint_sha256: key_fingerprint,
      user: user
    }
  end

  it_behaves_like 'having unique enum values'

  it_behaves_like 'commit signature' do
    let(:signature_attributes) { { commit_sha: commit_sha, project: signature.project } }

    it 'creates separate signatures for the same commit_sha in different projects' do
      project2 = create(:project, :repository)

      signature1 = described_class.safe_create!(attributes.merge(project: project))
      signature2 = described_class.safe_create!(attributes.merge(project: project2))

      expect(signature1).not_to eq(signature2)
      expect(signature1.project_id).to eq(project.id)
      expect(signature2.project_id).to eq(project2.id)
      expect(signature1.commit_sha).to eq(signature2.commit_sha)
    end
  end

  it_behaves_like 'signature with type checking', :ssh

  describe 'associations' do
    it { is_expected.to belong_to(:key).optional }
  end

  describe '.by_commit_sha scope' do
    let!(:another_signature) { create(:ssh_signature, commit_sha: '0000000000000000000000000000000000000001') }

    it 'returns all signatures by sha' do
      expect(described_class.by_commit_sha(commit_sha)).to match_array([signature])
      expect(
        described_class.by_commit_sha([commit_sha, another_signature.commit_sha])
      ).to contain_exactly(signature, another_signature)
    end
  end

  describe '#key_fingerprint_sha256' do
    it 'returns the fingerprint_sha256 associated with the SSH key' do
      expect(signature.key_fingerprint_sha256).to eq(key_fingerprint)
    end

    context 'when the SSH key is no longer associated with the signature' do
      it 'returns the fingerprint_sha256 stored in signature' do
        signature.update!(key_id: nil)

        expect(signature.key_fingerprint_sha256).to eq(key_fingerprint)
      end
    end
  end

  describe '#signed_by_user' do
    it 'returns the user associated with the SSH key' do
      expect(signature.signed_by_user).to eq(ssh_key.user)
    end

    context 'when the SSH key is no longer associated with the signature' do
      it 'returns the user stored in signature' do
        signature.update!(key_id: nil)

        expect(signature.signed_by_user).to eq(user)
      end
    end
  end

  describe '#verification_status' do
    before do
      allow(signature.project).to receive(:commit).with(commit_sha).and_return(commit)
      allow(commit).to receive(:committer_email).and_return(committer_email)
    end

    let(:committer_email) { user.email }

    context 'when persisted verification_status is verified' do
      it 'returns verified' do
        expect(signature.verification_status).to eq('verified')
      end

      context 'and the committer email does not belong to the signed by user' do
        let(:committer_email) { "unverified_email@test.com" }

        it 'returns unverified_author_email' do
          expect(signature.verification_status).to eq('unverified_author_email')
        end

        context 'when check_for_mailmapped_commit_emails feature flag is disabled' do
          before do
            stub_feature_flags(check_for_mailmapped_commit_emails: false)
          end

          it 'verification status is unmodified' do
            expect(signature.verification_status).to eq('verified')
          end
        end
      end
    end

    context 'when persisted verification_status not verified' do
      let(:signature) { create(:ssh_signature, verification_status: 'unverified') }

      it 'returns the signature verification status' do
        expect(signature.verification_status).to eq('unverified')
      end
    end

    context 'when verification_status is verified_system' do
      let(:verification_status) { :verified_system }

      let(:signature_committer_email) { 'committer-email-from-gitaly@email.com' }
      let(:committer_email) { 'verified-email@email.com' }

      let(:commit) { create(:commit, project: project, sha: commit_sha, committer_email: committer_email) }

      let(:signature) do
        create(:ssh_signature, commit_sha: commit_sha, key: ssh_key, key_fingerprint_sha256: key_fingerprint,
          user: user, verification_status: verification_status, committer_email: signature_committer_email)
      end

      let(:mock_user) do
        instance_double(User,
          verified_emails: [signature_committer_email, committer_email])
      end

      before do
        allow(User).to receive(:find_by_any_email)
                         .with(signature_committer_email, confirmed: true)
                         .and_return(mock_user)
      end

      context 'when commit committer email is included in verified emails' do
        it 'returns verified_system' do
          expect(signature.verification_status).to eq('verified_system')
        end
      end

      context 'when commit committer email is not included in verified emails' do
        before do
          allow(project).to receive(:commit).with(commit_sha).and_return(commit)
          allow(commit).to receive(:committer_email).and_return('unverified-email@email.com')
        end

        it 'returns unverified_author_email' do
          expect(signature.verification_status).to eq('unverified_author_email')
        end
      end

      context 'when check_for_mailmapped_commit_emails feature flag is disabled' do
        before do
          stub_feature_flags(check_for_mailmapped_commit_emails: false)
        end

        it 'verification status is unmodified' do
          expect(signature.verification_status).to eq('verified_system')
        end
      end
    end
  end
end
