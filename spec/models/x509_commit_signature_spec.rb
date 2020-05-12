# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509CommitSignature do
  let(:commit_sha) { '189a6c924013fc3fe40d6f1ec1dc20214183bc97' }
  let(:project) { create(:project, :public, :repository) }
  let!(:commit) { create(:commit, project: project, sha: commit_sha) }
  let(:x509_certificate) { create(:x509_certificate) }
  let(:x509_signature) { create(:x509_commit_signature, commit_sha: commit_sha) }

  let(:attributes) do
    {
      commit_sha: commit_sha,
      project: project,
      x509_certificate_id: x509_certificate.id,
      verification_status: "verified"
    }
  end

  it_behaves_like 'having unique enum values'

  describe 'validation' do
    it { is_expected.to validate_presence_of(:commit_sha) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:x509_certificate_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:x509_certificate).required }
  end

  describe '.safe_create!' do
    it 'finds a signature by commit sha if it existed' do
      x509_signature

      expect(described_class.safe_create!(commit_sha: commit_sha)).to eq(x509_signature)
    end

    it 'creates a new signature if it was not found' do
      expect { described_class.safe_create!(attributes) }.to change { described_class.count }.by(1)
    end

    it 'assigns the correct attributes when creating' do
      signature = described_class.safe_create!(attributes)

      expect(signature.project).to eq(project)
      expect(signature.commit_sha).to eq(commit_sha)
      expect(signature.x509_certificate_id).to eq(x509_certificate.id)
    end
  end

  describe '#user' do
    context 'if email is assigned to a user' do
      let!(:user) { create(:user, email: X509Helpers::User1.certificate_email) }

      it 'returns user' do
        expect(described_class.safe_create!(attributes).user).to eq(user)
      end
    end

    it 'if email is not assigned to a user, return nil' do
      expect(described_class.safe_create!(attributes).user).to be_nil
    end
  end
end
