# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Smime::Certificate do
  include SmimeHelper

  # cert generation is an expensive operation and they are used read-only,
  # so we share them as instance variables in all tests
  before :context do
    @root_ca = generate_root
    @intermediate_ca = generate_intermediate(signer_ca: @root_ca)
    @cert = generate_cert(signer_ca: @intermediate_ca)
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
