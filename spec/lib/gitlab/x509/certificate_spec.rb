# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::X509::Certificate, feature_category: :source_code_management do
  include SmimeHelper

  let(:sample_ca_certs_path) { Rails.root.join('spec/fixtures/clusters').to_s }
  let(:sample_cert) { Rails.root.join('spec/fixtures/x509_certificate.crt').to_s }

  # cert generation is an expensive operation and they are used read-only,
  # so we share them as instance variables in all tests
  before :context do
    @root_ca = generate_root
    @intermediate_ca = generate_intermediate(signer_ca: @root_ca)
    @cert = generate_cert(signer_ca: @intermediate_ca)
  end

  before do
    stub_const("OpenSSL::X509::DEFAULT_CERT_DIR", sample_ca_certs_path)
    stub_const("OpenSSL::X509::DEFAULT_CERT_FILE", sample_cert)
    described_class.reset_ca_certs_bundle
  end

  after(:context) do
    described_class.reset_ca_certs_bundle
  end

  describe 'testing environment setup' do
    describe 'generate_root' do
      subject { @root_ca }

      it 'generates a root CA that expires a long way in the future' do
        expect(subject[:cert].not_after).to be > 999.years.from_now
      end
    end

    describe 'generate_intermediate' do
      subject { @intermediate_ca }

      it 'generates an intermediate CA that expires a long way in the future' do
        expect(subject[:cert].not_after).to be > 999.years.from_now
      end

      it 'generates an intermediate CA properly signed by the root CA' do
        expect(subject[:cert].issuer).to eq(@root_ca[:cert].subject)
      end
    end

    describe 'generate_cert' do
      subject { @cert }

      it 'generates a cert properly signed by the intermediate CA' do
        expect(subject[:cert].issuer).to eq(@intermediate_ca[:cert].subject)
      end

      it 'generates a cert that expires soon' do
        expect(subject[:cert].not_after).to be < 60.minutes.from_now
      end

      it 'generates a cert intended for email signing' do
        expect(subject[:cert].extensions).to include(an_object_having_attributes(oid: 'extendedKeyUsage', value: match('E-mail Protection')))
      end

      context 'passing in INFINITE_EXPIRY' do
        subject { generate_cert(signer_ca: @intermediate_ca, expires_in: SmimeHelper::INFINITE_EXPIRY) }

        it 'generates a cert that expires a long way in the future' do
          expect(subject[:cert].not_after).to be > 999.years.from_now
        end
      end
    end
  end

  describe '.from_strings' do
    it 'parses correctly a certificate and key' do
      parsed_cert = described_class.from_strings(@cert[:key].to_s, @cert[:cert].to_pem)

      common_cert_tests(parsed_cert, @cert, @intermediate_ca)
    end
  end

  describe '.from_files' do
    it 'parses correctly a certificate and key' do
      stub_file_read('a_key', content: @cert[:key].to_s)
      stub_file_read('a_cert', content: @cert[:cert].to_pem)

      parsed_cert = described_class.from_files('a_key', 'a_cert')

      common_cert_tests(parsed_cert, @cert, @intermediate_ca)
    end

    context 'with optional ca_certs' do
      it 'parses correctly certificate, key and ca_certs' do
        stub_file_read('a_key', content: @cert[:key].to_s)
        stub_file_read('a_cert', content: @cert[:cert].to_pem)
        stub_file_read('a_ca_cert', content: @intermediate_ca[:cert].to_pem)

        parsed_cert = described_class.from_files('a_key', 'a_cert', 'a_ca_cert')

        common_cert_tests(parsed_cert, @cert, @intermediate_ca, with_ca_certs: [@intermediate_ca[:cert]])
      end
    end
  end

  context 'with no intermediate CA' do
    it 'parses correctly a certificate and key' do
      cert = generate_cert(signer_ca: @root_ca)

      stub_file_read('a_key', content: cert[:key].to_s)
      stub_file_read('a_cert', content: cert[:cert].to_pem)

      parsed_cert = described_class.from_files('a_key', 'a_cert')

      common_cert_tests(parsed_cert, cert, @root_ca)
    end
  end

  describe '.default_cert_dir' do
    before do
      described_class.reset_default_cert_paths
    end

    after(:context) do
      described_class.reset_default_cert_paths
    end

    context 'when SSL_CERT_DIR env variable is not set' do
      before do
        stub_env('SSL_CERT_DIR', nil)
      end

      it 'returns default directory from OpenSSL' do
        expect(described_class.default_cert_dir).to eq(OpenSSL::X509::DEFAULT_CERT_DIR)
      end
    end

    context 'when SSL_CERT_DIR env variable is set' do
      before do
        stub_env('SSL_CERT_DIR', '/tmp/foo/certs')
      end

      it 'returns specified directory' do
        expect(described_class.default_cert_dir).to eq('/tmp/foo/certs')
      end
    end
  end

  describe '.default_cert_file' do
    before do
      described_class.reset_default_cert_paths
    end

    after(:context) do
      described_class.reset_default_cert_paths
    end

    context 'when SSL_CERT_FILE env variable is not set' do
      before do
        stub_env('SSL_CERT_FILE', nil)
      end

      it 'returns default file from OpenSSL' do
        expect(described_class.default_cert_file).to eq(OpenSSL::X509::DEFAULT_CERT_FILE)
      end
    end

    context 'when SSL_CERT_FILE env variable is set' do
      before do
        stub_env('SSL_CERT_FILE', '/tmp/foo/cert.pem')
      end

      it 'returns specified file' do
        expect(described_class.default_cert_file).to eq('/tmp/foo/cert.pem')
      end
    end
  end

  describe '.ca_certs_paths' do
    it 'returns all files specified by OpenSSL defaults' do
      cert_paths = Dir["#{described_class.default_cert_dir}/*"]

      expect(described_class.ca_certs_paths).to match_array(cert_paths + [sample_cert])
    end
  end

  describe '.ca_certs_bundle' do
    it 'skips certificates if OpenSSLError is raised and report it' do
      expect(Gitlab::ErrorTracking)
        .to receive(:track_and_raise_for_dev_exception)
        .with(
          a_kind_of(OpenSSL::X509::CertificateError),
          cert_file: a_kind_of(String)).at_least(:once)

      expect(OpenSSL::X509::Certificate)
        .to receive(:new)
        .and_raise(OpenSSL::X509::CertificateError).at_least(:once)

      expect(described_class.ca_certs_bundle).to be_a(String)
    end

    it 'returns a list certificates as strings' do
      expect(described_class.ca_certs_bundle).to be_a(String)
    end
  end

  describe '.load_ca_certs_bundle' do
    it 'loads a PEM-encoded certificate bundle into an OpenSSL::X509::Certificate array' do
      ca_certs_string = described_class.ca_certs_bundle
      ca_certs = described_class.load_ca_certs_bundle(ca_certs_string)

      expect(ca_certs).to all(be_an(OpenSSL::X509::Certificate))
    end
  end

  def common_cert_tests(parsed_cert, cert, signer_ca, with_ca_certs: nil)
    expect(parsed_cert.cert).to be_a(OpenSSL::X509::Certificate)
    expect(parsed_cert.cert.subject).to eq(cert[:cert].subject)
    expect(parsed_cert.cert.issuer).to eq(signer_ca[:cert].subject)
    expect(parsed_cert.cert.not_before).to eq(cert[:cert].not_before)
    expect(parsed_cert.cert.not_after).to eq(cert[:cert].not_after)
    expect(parsed_cert.cert.extensions).to include(an_object_having_attributes(oid: 'extendedKeyUsage', value: match('E-mail Protection')))
    expect(parsed_cert.key).to be_a(OpenSSL::PKey::RSA)
    expect(parsed_cert.ca_certs).to match_array(Array.wrap(with_ca_certs)) if with_ca_certs
  end
end
