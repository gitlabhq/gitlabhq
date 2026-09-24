# frozen_string_literal: true

require 'fast_spec_helper'
require 'active_support/testing/time_helpers'

RSpec.describe SupplyChain::RootCaDriver, :aggregate_failures, feature_category: :artifact_security do
  include ActiveSupport::Testing::TimeHelpers

  let(:gitlab_url) { 'https://gitlab.example.com' }
  let(:ci_config_ref_uri) { 'gitlab.example.com/group/project//.gitlab-ci.yml@refs/heads/main' }
  let(:ca_key) { OpenSSL::PKey::EC.generate(described_class::EC_CURVE) }
  let(:stored_certificate) { nil }

  let(:driver_class) do
    Class.new(described_class) do
      attr_reader :provision_count

      def initialize(ca_key:, stored_certificate: nil)
        @ca_key = ca_key
        @stored_certificate = stored_certificate
        @provision_count = 0
      end

      private

      def fetch_ca
        @stored_certificate
      end

      def provision_ca!
        @provision_count += 1
        certificate = build_ca_certificate(key: @ca_key)
        certificate.sign(@ca_key, digest)

        @stored_certificate = certificate
      end

      def sign_with_ca(certificate)
        certificate.sign(@ca_key, digest)
      end
    end
  end

  let(:driver) { driver_class.new(ca_key: ca_key, stored_certificate: stored_certificate) }

  around do |example|
    freeze_time { example.run }
  end

  before do
    allow(Gitlab.config.gitlab).to receive_messages(url: gitlab_url, protocol: 'https')
  end

  def stored_ca(not_after:)
    certificate = described_class.new.send(:build_ca_certificate, key: ca_key)
    certificate.not_after = not_after

    certificate.sign(ca_key, OpenSSL::Digest.new(described_class::DIGEST_ALGORITHM))
  end

  describe 'abstract storage hooks' do
    let(:abstract_driver) { described_class.new }

    it 'requires fetch_ca to be implemented' do
      expect { abstract_driver.ca_certificate }.to raise_error(Gitlab::AbstractMethodError)
    end

    it 'requires provision_ca! to be implemented' do
      expect { abstract_driver.send(:provision_ca!) }.to raise_error(Gitlab::AbstractMethodError)
    end

    it 'requires sign_with_ca to be implemented' do
      expect { abstract_driver.send(:sign_with_ca, Object.new) }.to raise_error(Gitlab::AbstractMethodError)
    end
  end

  describe '#ca_certificate' do
    subject(:ca_certificate) { driver.ca_certificate }

    let(:minimum_ca_expiry) do
      (described_class::LEAF_VALIDITY + described_class::CLOCK_SKEW).from_now
    end

    context 'when no CA exists' do
      it 'provisions a self-signed CA certificate' do
        extensions = ca_certificate.extensions.index_by(&:oid)

        expect(driver.provision_count).to eq(1)
        expect(ca_certificate.subject.to_s).to eq('/CN=ca/DC=gitlab')
        expect(ca_certificate.verify(ca_key)).to be(true)
        expect(extensions['basicConstraints'].value).to eq('CA:TRUE')
        expect(extensions['keyUsage'].value).to eq('Certificate Sign, CRL Sign')
        expect(ca_certificate.not_before).to eq(described_class::CLOCK_SKEW.ago)
        expect(ca_certificate.not_after).to eq(described_class::CA_VALIDITY.from_now)
      end
    end

    context 'when the stored CA covers a new leaf certificate plus clock skew' do
      let(:stored_certificate) { stored_ca(not_after: minimum_ca_expiry) }

      it 'returns it without provisioning a new one' do
        expect(ca_certificate.to_der).to eq(stored_certificate.to_der)
        expect(driver.provision_count).to eq(0)
      end
    end

    context 'when the stored CA expires one second too soon' do
      let(:stored_certificate) { stored_ca(not_after: minimum_ca_expiry - 1.second) }

      it 'raises InvalidCaCertificate' do
        expect { ca_certificate }.to raise_error(described_class::InvalidCaCertificate)
        expect(driver.provision_count).to eq(0)
      end
    end

    context 'when provisioning hands back a CA that expires too soon' do
      let(:driver_class) do
        Class.new(super()) do
          private

          def provision_ca!
            super.tap do |certificate|
              certificate.not_after = 1.month.from_now
              certificate.sign(@ca_key, digest)
            end
          end
        end
      end

      it 'raises InvalidCaCertificate instead of trusting the provisioned certificate' do
        expect { ca_certificate }.to raise_error(described_class::InvalidCaCertificate)
        expect(driver.provision_count).to eq(1)
      end
    end
  end

  describe '#generate_leaf_certificate' do
    subject(:leaf) { driver.generate_leaf_certificate(ci_config_ref_uri: ci_config_ref_uri) }

    it 'returns a P-256 key and a leaf certificate signed by the CA' do
      expect(leaf.key.group.curve_name).to eq(described_class::EC_CURVE)
      expect(leaf.certificate.check_private_key(leaf.key)).to be(true)
      expect(leaf.certificate.verify(ca_key)).to be(true)
      expect(leaf.certificate.issuer).to eq(driver.ca_certificate.subject)
      expect(leaf.certificate.not_before).to eq(described_class::CLOCK_SKEW.ago)
      expect(leaf.certificate.not_after).to eq(described_class::LEAF_VALIDITY.from_now)
    end

    it 'identifies the pipeline in the SAN and the instance in the Fulcio issuer extension' do
      extensions = leaf.certificate.extensions.index_by(&:oid)
      issuer = OpenSSL::ASN1.decode(extensions[described_class::FULCIO_ISSUER_OID].value_der).value

      expect(leaf.certificate.subject.to_a).to be_empty
      expect(extensions['subjectAltName'].value).to eq("URI:https://#{ci_config_ref_uri}")
      expect(extensions['subjectAltName'].critical?).to be(true)
      expect(issuer).to eq(gitlab_url)
      expect(extensions['basicConstraints'].value).to eq('CA:FALSE')
      expect(extensions['keyUsage'].value).to eq('Digital Signature')
      expect(extensions['extendedKeyUsage'].value).to eq('Code Signing')
    end

    context 'when ci_config_ref_uri is blank' do
      let(:ci_config_ref_uri) { '' }

      it 'raises InvalidInput' do
        expect { leaf }.to raise_error(described_class::InvalidInput, /required/)
        expect(driver.provision_count).to eq(0)
      end
    end
  end
end
