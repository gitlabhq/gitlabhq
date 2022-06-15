# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::FIPS do
  describe ".enabled?" do
    subject { described_class.enabled? }

    let(:openssl_fips_mode) { false }
    let(:fips_mode_env_var) { nil }

    before do
      expect(OpenSSL).to receive(:fips_mode).and_return(openssl_fips_mode)
      stub_env("FIPS_MODE", fips_mode_env_var)
    end

    describe "OpenSSL auto-detection" do
      context "OpenSSL is in FIPS mode" do
        let(:openssl_fips_mode) { true }

        it { is_expected.to be_truthy }
      end

      context "OpenSSL is not in FIPS mode" do
        let(:openssl_fips_mode) { false }

        it { is_expected.to be_falsey }
      end
    end

    describe "manual configuration via env var" do
      context "env var is not set" do
        let(:fips_mode_env_var) { nil }

        it { is_expected.to be_falsey }
      end

      context "env var is set to true" do
        let(:fips_mode_env_var) { "true" }

        it { is_expected.to be_truthy }
      end

      context "env var is set to false" do
        let(:fips_mode_env_var) { "false" }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '.enable_fips_mode!' do
    let(:digests) { {} }
    let(:test_string) { 'abc' }

    before do
      described_class::OPENSSL_DIGESTS.each do |digest|
        digests[digest] = Digest.const_get(digest, false)
      end
    end

    after do
      digests.each do |name, value|
        Digest.send(:remove_const, name)
        Digest.const_set(name, value)
      end
    end

    it 'assigns OpenSSL digests' do
      described_class.enable_fips_mode!

      # rubocop:disable Fips/OpenSSL
      # rubocop:disable Fips/SHA1
      # rubocop:disable Layout/LineLength
      expect(Digest::SHA1).to be(OpenSSL::Digest::SHA1)
      expect(Digest::SHA2).to be(OpenSSL::Digest::SHA256)
      expect(Digest::SHA256).to be(OpenSSL::Digest::SHA256)
      expect(Digest::SHA384).to be(OpenSSL::Digest::SHA384)
      expect(Digest::SHA512).to be(OpenSSL::Digest::SHA512)

      # From https://www.nist.gov/itl/ssd/software-quality-group/nsrl-test-data
      expect(Digest::SHA1.hexdigest(test_string)).to eq('a9993e364706816aba3e25717850c26c9cd0d89d')
      expect(Digest::SHA2.hexdigest(test_string)).to eq('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
      expect(Digest::SHA256.hexdigest(test_string)).to eq('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
      expect(Digest::SHA384.hexdigest(test_string)).to eq('cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7')
      expect(Digest::SHA512.hexdigest(test_string)).to eq('ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f')

      expect(Digest::SHA1.base64digest(test_string)).to eq('qZk+NkcGgWq6PiVxeFDCbJzQ2J0=')
      expect(Digest::SHA2.base64digest(test_string)).to eq('ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=')
      expect(Digest::SHA256.base64digest(test_string)).to eq('ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=')
      expect(Digest::SHA384.base64digest(test_string)).to eq('ywB1P0WjXou1oD1pmsZQBycsMqsO3tFjGotgWkP/W+2AhgcroefMI1i67KE0yCWn')
      expect(Digest::SHA512.base64digest(test_string)).to eq('3a81oZNherrMQXNJriBBMRLm+k6JqX6iCp7u5ktV05ohkpkqJ0/BqDa6PCOj/uu9RU1EI2Q86A4qmslPpUyknw==')
      # rubocop:enable Fips/OpenSSL
      # rubocop:enable Fips/SHA1
      # rubocop:enable Layout/LineLength
    end
  end
end
