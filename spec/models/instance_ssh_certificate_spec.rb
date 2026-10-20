# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceSshCertificate, feature_category: :source_code_management, fips_mode: false do
  subject { build(:instance_ssh_certificate) }

  it_behaves_like 'an SSH certificate record', factory_name: :instance_ssh_certificate

  describe 'fingerprint uniqueness' do
    it 'rejects a duplicate fingerprint instance-wide' do
      existing = create(:instance_ssh_certificate)

      duplicate = build(:instance_ssh_certificate, key: existing.key)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:fingerprint]).to include(
        'must be unique. This CA has already been configured.'
      )
    end

    it 'is enforced by a unique index when model validation is skipped' do
      existing = create(:instance_ssh_certificate)

      # Skipping validation also skips the callback that derives the fingerprint, so set it here.
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
end
