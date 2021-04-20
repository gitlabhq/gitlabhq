# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509CertificateCredentialsValidator do
  let(:certificate_data) { File.read('spec/fixtures/x509_certificate.crt') }
  let(:pkey_data) { File.read('spec/fixtures/x509_certificate_pk.key') }

  let(:validatable) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :certificate, :private_key, :passphrase

      def initialize(certificate, private_key, passphrase = nil)
        @certificate = certificate
        @private_key = private_key
        @passphrase = passphrase
      end
    end
  end

  subject(:validator) do
    described_class.new(certificate: :certificate, pkey: :private_key)
  end

  it 'is not valid when the certificate is not valid' do
    record = validatable.new('not a certificate', nil)

    validator.validate(record)

    expect(record.errors[:certificate]).to include('is not a valid X509 certificate.')
  end

  it 'is not valid without a certificate' do
    record = validatable.new(nil, nil)

    validator.validate(record)

    expect(record.errors[:certificate]).not_to be_empty
  end

  context 'when a valid certificate is passed' do
    let(:record) { validatable.new(certificate_data, nil) }

    it 'does not track an error for the certificate' do
      validator.validate(record)

      expect(record.errors[:certificate]).to be_empty
    end

    it 'adds an error when not passing a correct private key' do
      validator.validate(record)

      expect(record.errors[:private_key]).to include('could not read private key, is the passphrase correct?')
    end

    it 'has no error when the private key is correct' do
      record.private_key = pkey_data

      validator.validate(record)

      expect(record.errors).to be_empty
    end
  end

  context 'when using a passphrase' do
    let(:passphrase_certificate_data) { File.read('spec/fixtures/passphrase_x509_certificate.crt') }
    let(:passphrase_pkey_data) { File.read('spec/fixtures/passphrase_x509_certificate_pk.key') }

    let(:record) { validatable.new(passphrase_certificate_data, passphrase_pkey_data, '5iveL!fe') }

    subject(:validator) do
      described_class.new(certificate: :certificate, pkey: :private_key, pass: :passphrase)
    end

    it 'is valid with the correct data' do
      validator.validate(record)

      expect(record.errors).to be_empty
    end

    it 'adds an error when the passphrase is wrong' do
      record.passphrase = 'wrong'

      validator.validate(record)

      expect(record.errors[:private_key]).not_to be_empty
    end
  end
end
