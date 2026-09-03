# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceSshCertificate, feature_category: :source_code_management, fips_mode: false do
  subject { build(:instance_ssh_certificate) }

  describe 'validations' do
    it 'presence fields' do
      is_expected.to validate_presence_of(:key)
      is_expected.to validate_presence_of(:title)
      is_expected.to validate_presence_of(:fingerprint)
    end

    it 'length of key and title' do
      is_expected.to validate_length_of(:title).is_at_most(255)
      is_expected.to validate_length_of(:key).is_at_most(5000)
    end

    it 'format of the key' do
      is_expected.to allow_value(build(:rsa_key_4096).key).for(:key)
      is_expected.not_to allow_value('unsupported-ssh-rsa key').for(:key)
    end

    it_behaves_like 'meets ssh key restrictions'
  end

  describe 'fingerprint uniqueness' do
    it 'rejects a duplicate fingerprint instance-wide' do
      existing = create(:instance_ssh_certificate)

      duplicate = build(:instance_ssh_certificate, fingerprint: existing.fingerprint)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:fingerprint]).to include(
        'must be unique. This CA has already been configured.'
      )
    end

    it 'is enforced by a unique index when model validation is skipped' do
      existing = create(:instance_ssh_certificate)

      duplicate = build(:instance_ssh_certificate, fingerprint: existing.fingerprint)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'FIPS key validation', :fips_mode do
    it 'rejects a DSA CA key because DSA is not FIPS-approved' do
      certificate = build(:instance_ssh_certificate, key: build(:dsa_key_2048).key)

      expect(certificate).to be_invalid
      expect(certificate.errors[:key]).to include(
        a_string_matching(/type is forbidden/)
      )
    end

    it 'rejects a 2048-bit RSA CA key as below the FIPS minimum size' do
      certificate = build(:instance_ssh_certificate, key: build(:rsa_key_2048).key)

      expect(certificate).to be_invalid
      expect(certificate.errors[:key]).to include('must be at least 3072 bits')
    end

    it 'accepts a 4096-bit RSA CA key' do
      certificate = build(:instance_ssh_certificate, key: build(:rsa_key_4096).key)

      expect(certificate).to be_valid
    end
  end

  describe '.available?' do
    it { expect(described_class).to be_available }

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(instance_ssh_certificates: false)
      end

      it { expect(described_class).not_to be_available }
    end

    context 'on GitLab.com', :saas do
      it { expect(described_class).not_to be_available }
    end
  end

  describe '.for_fingerprint' do
    let_it_be(:certificate) { create(:instance_ssh_certificate) }
    let_it_be(:other_certificate) { create(:instance_ssh_certificate) }

    it 'returns only the certificate matching the fingerprint' do
      expect(described_class.for_fingerprint(certificate.fingerprint)).to contain_exactly(certificate)
    end

    it 'returns empty when no certificate matches' do
      expect(described_class.for_fingerprint('nonexistent')).to be_empty
    end
  end
end
