# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::FIPS do
  describe ".enabled?" do
    subject { described_class.enabled? }

    let(:openssl_fips_mode) { false }
    let(:fips_mode_env_var) { nil }

    before do
      allow(OpenSSL).to receive(:fips_mode).and_return(openssl_fips_mode)
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
end
