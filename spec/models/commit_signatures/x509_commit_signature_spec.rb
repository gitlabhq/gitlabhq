# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignatures::X509CommitSignature do
  # This commit is seeded from https://gitlab.com/gitlab-org/gitlab-test
  # For instructions on how to add more seed data, see the project README
  let_it_be(:commit_sha) { '189a6c924013fc3fe40d6f1ec1dc20214183bc97' }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:commit) { create(:commit, project: project, sha: commit_sha) }
  let_it_be(:x509_certificate) { create(:x509_certificate) }

  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      x509_certificate_id: x509_certificate.id,
      verification_status: "verified"
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
end
