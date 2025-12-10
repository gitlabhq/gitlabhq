# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignatures::X509CommitSignature, feature_category: :source_code_management do
  # This commit is seeded from https://gitlab.com/gitlab-org/gitlab-test
  # For instructions on how to add more seed data, see the project README
  # The email for this commit is 'r.meier@siemens.com'
  let_it_be(:commit_sha) { '189a6c924013fc3fe40d6f1ec1dc20214183bc97' }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:commit) { create(:commit, project: project, sha: commit_sha) }
  let_it_be(:x509_certificate) { create(:x509_certificate, email: 'r.meier@siemens.com') }
  let_it_be(:verification_status) { "unverified_author_email" }
  let_it_be(:committer_email) { nil }

  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      x509_certificate_id: x509_certificate.id,
      verification_status: verification_status,
      committer_email: committer_email
    }
  end

  let(:signature) { create(:x509_commit_signature, commit_sha: commit_sha, x509_certificate: x509_certificate) }

  it_behaves_like 'having unique enum values'

  it_behaves_like 'commit signature' do
    let(:signature_attributes) { { commit_sha: commit_sha } }
  end

  it_behaves_like 'signature with type checking', :x509

  describe 'validation' do
    it { is_expected.to validate_presence_of(:x509_certificate_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:x509_certificate).required }
  end

  describe '#user' do
    context 'if email is assigned to a user' do
      let!(:user) { create(:user, email: X509Helpers::User1.certificate_email) }

      it 'returns user' do
        expect(described_class.safe_create!(attributes).signed_by_user).to eq(user)
      end
    end

    it 'if email is not assigned to a user, return nil' do
      expect(described_class.safe_create!(attributes).signed_by_user).to be_nil
    end
  end

  describe '#verification_status' do
    let_it_be(:matching_email) { 'r.meier@siemens.com' }
    let_it_be(:verification_status) { "verified" }

    subject(:signature) { described_class.safe_create!(attributes) }

    context 'when the commit email matches certificate emails' do
      shared_examples 'verification based on committer email verification' do
        let_it_be(:committer_email) { matching_email }

        context 'when the commit email is verified for the author' do
          let_it_be(:user) { create(:user, email: matching_email) }

          it 'returns verified' do
            expect(signature.verification_status).to eq('verified')
          end
        end

        context 'when the committer email is not verified for the author' do
          let_it_be(:user) { create(:user) }

          it 'returns unverified_author_email' do
            expect(signature.verification_status).to eq('unverified_author_email')
          end
        end
      end

      context 'when the commit email matches the primary x509 certificate email' do
        let_it_be(:x509_certificate) { create(:x509_certificate, email: matching_email) }

        include_examples 'verification based on committer email verification'
      end

      context 'when the commit email matches one of the x509 certificate secondary emails' do
        let_it_be(:x509_certificate) do
          create(:x509_certificate,
            email: 'different@test.com',
            emails: [matching_email, 'also-different@test.com']
          )
        end

        include_examples 'verification based on committer email verification'
      end
    end

    context 'when the commit email does not match any of the x509 certificate emails' do
      let_it_be(:x509_certificate) do
        create(:x509_certificate,
          email: 'different@test.com',
          emails: ['also-different@test.com', 'irrelevant@test.com']
        )
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
        expect(signature.verification_status).to eq('verified')
      end
    end
  end
end
