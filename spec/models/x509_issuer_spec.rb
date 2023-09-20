# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509Issuer do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:subject_key_identifier) }
  end

  describe '.safe_create!' do
    let(:issuer_subject_key_identifier) { 'AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB' }
    let(:issuer_subject) { 'CN=PKI,OU=Example,O=World' }
    let(:issuer_crl_url) { 'http://example.com/pki.crl' }

    let(:attributes) do
      {
        subject_key_identifier: issuer_subject_key_identifier,
        subject: issuer_subject,
        crl_url: issuer_crl_url
      }
    end

    it 'creates a new issuer if it was not found' do
      expect { described_class.safe_create!(attributes) }.to change { described_class.count }.by(1)
    end

    it 'assigns the correct attributes when creating' do
      issuer = described_class.safe_create!(attributes)

      expect(issuer.subject_key_identifier).to eq(issuer_subject_key_identifier)
      expect(issuer.subject).to eq(issuer_subject)
      expect(issuer.crl_url).to eq(issuer_crl_url)
    end
  end

  describe 'validators' do
    it 'accepts correct subject_key_identifier' do
      subject_key_identifiers = [
        'AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB',
        'CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD',
        '79:FB:C1:E5:6B:53:8B:0A',
        '79:fb:c1:e5:6b:53:8b:0a'
      ]

      subject_key_identifiers.each do |identifier|
        expect(build(:x509_issuer, subject_key_identifier: identifier)).to be_valid
      end
    end

    it 'rejects invalid subject_key_identifier' do
      subject_key_identifiers = [
        'CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:GG',
        'random string',
        '12321342545356434523412341245452345623453542345234523453245'
      ]

      subject_key_identifiers.each do |identifier|
        expect(build(:x509_issuer, subject_key_identifier: identifier)).to be_invalid
      end
    end

    it 'accepts valid crl_url' do
      expect(build(:x509_issuer, crl_url: "https://pki.example.org")).to be_valid
    end

    it 'rejects invalid crl_url' do
      expect(build(:x509_issuer, crl_url: "ht://pki.example.org")).to be_invalid
    end
  end
end
