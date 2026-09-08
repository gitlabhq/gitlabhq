# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SupplyChain::SigningCertificate, feature_category: :artifact_security do
  subject(:signing_certificate) { build(:supply_chain_signing_certificate) }

  def generate_pair(not_after:)
    key = OpenSSL::PKey::RSA.new(2048)
    name = OpenSSL::X509::Name.parse('/CN=ca/DC=example')
    certificate = OpenSSL::X509::Certificate.new
    certificate.serial = 0
    certificate.version = 2
    certificate.not_before = 1.year.ago
    certificate.not_after = not_after
    certificate.public_key = key.public_key
    certificate.subject = name
    certificate.issuer = name
    certificate.sign(key, OpenSSL::Digest.new('SHA256'))

    [key.to_pem, certificate.to_pem]
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:private_key) }
    it { is_expected.to validate_presence_of(:certificate) }
    it { is_expected.to validate_presence_of(:expires_at) }
    it { is_expected.to validate_length_of(:certificate).is_at_most(described_class::CERTIFICATE_MAX_LENGTH) }
    it { is_expected.to allow_value(true, false).for(:active) }
    it { is_expected.not_to allow_value(nil).for(:active) }

    context 'with an oversized private key' do
      subject(:signing_certificate) do
        build(:supply_chain_signing_certificate, private_key: 'a' * (described_class::PRIVATE_KEY_MAX_LENGTH + 1))
      end

      it 'is invalid' do
        expect(signing_certificate).not_to be_valid
        expect(signing_certificate.errors[:private_key]).to be_present
      end
    end

    context 'with an invalid certificate' do
      subject(:signing_certificate) { build(:supply_chain_signing_certificate, certificate: 'not-a-pem') }

      it 'is invalid' do
        expect(signing_certificate).not_to be_valid
        expect(signing_certificate.errors[:certificate]).to include('must be a valid PEM certificate')
      end
    end

    context 'with an invalid private key' do
      subject(:signing_certificate) { build(:supply_chain_signing_certificate, private_key: 'not-a-key') }

      it 'is invalid' do
        expect(signing_certificate).not_to be_valid
        expect(signing_certificate.errors[:private_key]).to include('must be a valid PEM private key')
      end
    end

    context 'with a private key that does not match the certificate' do
      subject(:signing_certificate) do
        build(:supply_chain_signing_certificate, private_key: OpenSSL::PKey::RSA.new(2048).to_pem)
      end

      it 'is invalid' do
        expect(signing_certificate).not_to be_valid
        expect(signing_certificate.errors[:private_key]).to include("doesn't match the certificate")
      end
    end

    describe 'expires_at' do
      it 'is derived from the certificate not_after' do
        certificate = OpenSSL::X509::Certificate.new(signing_certificate.certificate)

        expect(signing_certificate.expires_at).to eq(certificate.not_after)
      end

      it 'is cleared when the certificate becomes unparseable' do
        signing_certificate.certificate = 'garbage'
        signing_certificate.validate

        expect(signing_certificate.expires_at).to be_nil
        expect(signing_certificate.errors[:expires_at]).to include("can't be blank")
      end

      context 'with an expired certificate' do
        subject(:signing_certificate) do
          key, certificate = generate_pair(not_after: 1.day.ago)

          build(:supply_chain_signing_certificate, private_key: key, certificate: certificate)
        end

        it 'is invalid on create' do
          expect(signing_certificate).not_to be_valid
          expect(signing_certificate.errors[:expires_at]).to include('cannot be a date in the past')
        end
      end

      context 'when a persisted record expires' do
        subject(:signing_certificate) { create(:supply_chain_signing_certificate) }

        it 'remains valid on update' do
          signing_certificate.update_column(:expires_at, 1.day.ago)

          expect(signing_certificate.reload).to be_valid
        end
      end
    end

    describe 'active uniqueness per project' do
      let_it_be(:project) { create(:project) }
      let_it_be(:other_project) { create(:project) }

      let!(:existing) { create(:supply_chain_signing_certificate, project: project) }

      it 'rejects a second active certificate for the same project' do
        duplicate = build(:supply_chain_signing_certificate, project: project)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:active]).to include('has already been taken')
      end

      it 'allows an inactive certificate for the same project' do
        inactive = build(:supply_chain_signing_certificate, :inactive, project: project)

        expect(inactive).to be_valid
      end

      it 'allows an active certificate for a different project' do
        other = build(:supply_chain_signing_certificate, project: other_project)

        expect(other).to be_valid
      end

      it 'enforces uniqueness at the database level' do
        inactive = create(:supply_chain_signing_certificate, :inactive, project: project)

        expect do
          inactive.update_column(:active, true)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe 'encryption' do
    subject(:signing_certificate) { create(:supply_chain_signing_certificate) }

    let(:sample_key) { File.read(Rails.root.join('spec/fixtures/supply_chain/signing_key.key')) }

    it 'round-trips the private key' do
      expect(signing_certificate.reload.private_key).to eq(sample_key)
    end

    it 'stores the private key encrypted at rest' do
      ciphertext = signing_certificate.ciphertext_for(:private_key)

      expect(ciphertext).not_to include('PRIVATE KEY')
      expect(Gitlab::Json::SafeParser.parse(ciphertext)).to include('p', 'h')
    end

    it 'does not expose the private key in serialization' do
      expect(signing_certificate.serializable_hash).not_to include('private_key')
      expect(signing_certificate.to_json).not_to include('PRIVATE KEY')
    end
  end
end
