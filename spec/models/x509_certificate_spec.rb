# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509Certificate do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:subject_key_identifier) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:serial_number) }
    it { is_expected.to validate_presence_of(:x509_issuer_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:x509_issuer).required }
  end

  describe '.safe_create!' do
    let(:subject_key_identifier) { 'CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD' }
    let(:subject) { 'CN=gitlab@example.com,OU=Example,O=World' }
    let(:email) { 'gitlab@example.com' }
    let(:serial_number) { '123456789' }
    let(:issuer) { create(:x509_issuer) }

    let(:attributes) do
      {
        subject_key_identifier: subject_key_identifier,
        subject: subject,
        email: email,
        serial_number: serial_number,
        x509_issuer_id: issuer.id
      }
    end

    it 'creates a new certificate if it was not found' do
      expect { described_class.safe_create!(attributes) }.to change { described_class.count }.by(1)
    end

    it 'assigns the correct attributes when creating' do
      certificate = described_class.safe_create!(attributes)

      expect(certificate.subject_key_identifier).to eq(subject_key_identifier)
      expect(certificate.subject).to eq(subject)
      expect(certificate.email).to eq(email)
    end

    it 'calls mark_commit_signatures_unverified' do
      expect_any_instance_of(described_class).to receive(:mark_commit_signatures_unverified)

      described_class.safe_create!(attributes)
    end

    context 'certificate revocation handling' do
      let(:x509_certificate) { create(:x509_certificate) }

      it 'starts a revoke worker if certificate is revoked' do
        expect(X509CertificateRevokeWorker).to receive(:perform_async).with(x509_certificate.id)

        x509_certificate.revoked!
      end

      it 'does not starts a revoke worker for good certificates' do
        expect(X509CertificateRevokeWorker).not_to receive(:perform_async).with(x509_certificate.id)

        x509_certificate
      end
    end
  end

  describe 'validators' do
    let_it_be(:issuer) { create(:x509_issuer) }

    it 'accepts correct subject_key_identifier' do
      subject_key_identifiers = [
        'AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB',
        'CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD',
        '79:FB:C1:E5:6B:53:8B:0A',
        '79:fb:c1:e5:6b:53:8b:0a'
      ]

      subject_key_identifiers.each do |identifier|
        expect(build(:x509_certificate, x509_issuer: issuer, subject_key_identifier: identifier)).to be_valid
      end
    end

    it 'rejects invalid subject_key_identifier' do
      subject_key_identifiers = [
        'CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:GG',
        'random string',
        '12321342545356434523412341245452345623453542345234523453245'
      ]

      subject_key_identifiers.each do |identifier|
        expect(build(:x509_certificate, x509_issuer: issuer, subject_key_identifier: identifier)).to be_invalid
      end
    end

    it 'accepts correct email address' do
      emails = [
        'smime@example.org',
        'smime@example.com'
      ]

      emails.each do |email|
        expect(build(:x509_certificate, x509_issuer: issuer, email: email)).to be_valid
      end
    end

    it 'rejects invalid email' do
      emails = [
        'this is not an email',
        '@example.org'
      ]

      emails.each do |email|
        expect(build(:x509_certificate, x509_issuer: issuer, email: email)).to be_invalid
      end
    end

    it 'accepts valid serial_number' do
      expect(build(:x509_certificate, x509_issuer: issuer, serial_number: 123412341234)).to be_valid

      # rfc 5280 - 4.1.2.2  Serial number (20 octets is the maximum)
      expect(build(:x509_certificate, x509_issuer: issuer, serial_number: 1461501637330902918203684832716283019655932542975)).to be_valid
      expect(build(:x509_certificate, x509_issuer: issuer, serial_number: 'ffffffffffffffffffffffffffffffffffffffff'.to_i(16))).to be_valid
    end

    it 'rejects invalid serial_number' do
      expect(build(:x509_certificate, x509_issuer: issuer, serial_number: "sgsgfsdgdsfg")).to be_invalid
    end
  end

  describe '#all_emails' do
    it 'creates a new certificate if it was not found' do
      cert = build(:x509_certificate, email: 'user@example.com', emails: ['gitlab@test.com', 'test@test.com', 'user@example.com', nil])
      expect(cert.all_emails).to contain_exactly('user@example.com', 'gitlab@test.com', 'test@test.com')
    end
  end
end
