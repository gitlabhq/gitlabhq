# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignatures::GpgSignature, feature_category: :source_code_management do
  # This commit is seeded from https://gitlab.com/gitlab-org/gitlab-test
  # For instructions on how to add more seed data, see the project README
  let_it_be(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }
  let_it_be(:project) { create(:project, :repository, path: 'sample-project') }
  let_it_be(:gpg_key) { create(:gpg_key) }
  let_it_be(:gpg_key_subkey) { create(:gpg_key_subkey, gpg_key: gpg_key) }
  let(:commit) { create(:commit, project: project, sha: commit_sha).present(current_user: gpg_key.user) }

  let(:signature) { create(:gpg_signature, commit_sha: commit_sha, gpg_key: gpg_key) }

  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      gpg_key_primary_keyid: gpg_key.keyid
    }
  end

  it_behaves_like 'having unique enum values'
  it_behaves_like 'commit signature'
  it_behaves_like 'signature with type checking', :gpg

  describe 'associations' do
    it { is_expected.to belong_to(:gpg_key) }
    it { is_expected.to belong_to(:gpg_key_subkey) }
  end

  describe 'validation' do
    subject { described_class.new }

    it { is_expected.to validate_presence_of(:commit_sha) }
    it { is_expected.to validate_presence_of(:gpg_key_primary_keyid) }
  end

  describe '.by_commit_sha scope' do
    let_it_be(:another_gpg_signature) { create(:gpg_signature, gpg_key: gpg_key) }

    it 'returns all gpg signatures by sha' do
      expect(described_class.by_commit_sha(commit_sha)).to match_array([signature])
      expect(
        described_class.by_commit_sha([commit_sha, another_gpg_signature.commit_sha])
      ).to contain_exactly(signature, another_gpg_signature)
    end
  end

  describe '#gpg_key=' do
    it 'supports the assignment of a GpgKey' do
      signature = create(:gpg_signature, gpg_key: gpg_key)

      expect(signature.gpg_key).to be_an_instance_of(GpgKey)
    end

    it 'supports the assignment of a GpgKeySubkey' do
      signature = create(:gpg_signature, gpg_key: gpg_key_subkey)

      expect(signature.gpg_key).to be_an_instance_of(GpgKeySubkey)
    end

    it 'clears gpg_key and gpg_key_subkey_id when passing nil' do
      signature.update_attribute(:gpg_key, nil)

      expect(signature.gpg_key_id).to be_nil
      expect(signature.gpg_key_subkey_id).to be_nil
    end
  end

  describe '#gpg_commit' do
    context 'when commit does not exist' do
      it 'returns nil' do
        allow(signature).to receive(:commit).and_return(nil)

        expect(signature.gpg_commit).to be_nil
      end
    end

    context 'when commit exists' do
      it 'returns an instance of Gitlab::Gpg::Commit' do
        allow(signature).to receive(:commit).and_return(commit)

        expect(signature.gpg_commit).to be_an_instance_of(Gitlab::Gpg::Commit)
      end
    end
  end

  describe '#signed_by_user' do
    it 'retrieves the gpg_key user' do
      expect(signature.signed_by_user).to eq(gpg_key.user)
    end

    context 'when gpg_key is nil' do
      before do
        signature.update!(gpg_key_id: nil)
      end

      it 'returns nil' do
        expect(signature.signed_by_user).to be_nil
      end
    end
  end

  describe '#verification_status' do
    let(:verification_status) { :verified }
    let(:signature) do
      create(:gpg_signature, commit_sha: commit_sha, gpg_key: gpg_key, project: project,
        verification_status: verification_status)
    end

    # verified is used for user signed gpg commits.
    context 'when persisted verification_status is verified' do
      before do
        allow(project).to receive(:commit).with(commit_sha).and_return(commit)
        allow(commit).to receive(:committer_email).and_return(signature_committer_email)
      end

      let(:signature_committer_email) { gpg_key.user.email }

      it 'returns persisted verification status' do
        expect(signature.verification_status).to eq('verified')
      end

      context 'when commit committer does not match the gpg_key author' do
        let(:signature_committer_email) { 'no-match@example.org' }

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
      let(:verification_status) { :unverified }

      it 'returns the signature verification status' do
        expect(signature.verification_status).to eq('unverified')
      end
    end

    # verified_system is used for ui signed commits.
    context 'when persisted verification_status is verified_system' do
      let(:verification_status) { :verified_system }

      let(:signature_committer_email) { 'committer-email-from-gitaly@email.com' }
      let(:committer_email) { 'verified-email@email.com' }
      let(:commit) { create(:commit, project: project, sha: commit_sha) }

      let(:signature) do
        create(:gpg_signature, commit_sha: commit_sha, gpg_key: gpg_key, project: project,
          verification_status: verification_status, committer_email: signature_committer_email)
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

      context 'when committer email is not included in verified emails' do
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
