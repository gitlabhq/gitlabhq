# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignatures::X509CommitSignature do
  # This commit is seeded from https://gitlab.com/gitlab-org/gitlab-test
  # For instructions on how to add more seed data, see the project README
  # The email for this commit is 'r.meier@siemens.com'
  let_it_be(:commit_sha) { '189a6c924013fc3fe40d6f1ec1dc20214183bc97' }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:commit) { create(:commit, project: project, sha: commit_sha) }
  let_it_be(:x509_certificate) { create(:x509_certificate) }
  let_it_be(:verification_status) { "verified" }

  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      x509_certificate_id: x509_certificate.id,
      verification_status: verification_status
    }
  end

  let(:signature) { create(:x509_commit_signature, commit_sha: commit_sha, x509_certificate: x509_certificate) }

  it_behaves_like 'having unique enum values'
  it_behaves_like 'commit signature'
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

  describe '#reverified_status' do
    let_it_be(:matching_email) { 'r.meier@siemens.com' }

    subject(:reverified_status) { described_class.safe_create!(attributes).reverified_status }

    context 'when the commit email matches the x509 certificate emails' do
      let_it_be(:x509_certificate) { create(:x509_certificate, email: matching_email) }

      it 'returns verified' do
        expect(reverified_status).to eq('verified')
      end
    end

    context 'when the commit email matches one of the x509 certificate secondary emails' do
      let_it_be(:x509_certificate) do
        create(:x509_certificate,
          email: 'different@test.com',
          emails: [matching_email, 'also-different@test.com']
        )
      end

      it 'returns verified' do
        expect(reverified_status).to eq('verified')
      end
    end

    context 'when the commit email does not matche any of the x509 certificate emails' do
      let_it_be(:x509_certificate) do
        create(:x509_certificate,
          email: 'different@test.com',
          emails: ['also-different@test.com', 'irrelevant@test.com']
        )
      end

      it 'returns unverified_author_email' do
        expect(reverified_status).to eq('unverified_author_email')
      end
    end

    context 'when check_for_mailmapped_commit_emails feature flag is disabled' do
      before do
        stub_feature_flags(check_for_mailmapped_commit_emails: false)
      end

      it 'verification status is unmodified' do
        expect(reverified_status).to eq('verified')
      end
    end
  end
end
