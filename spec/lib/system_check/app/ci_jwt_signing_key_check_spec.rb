# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::App::CiJwtSigningKeyCheck do
  subject(:system_check) { described_class.new }

  describe '#check?' do
    it 'returns false when key is not present' do
      expect(Rails.application.secrets).to receive(:ci_jwt_signing_key).and_return(nil)

      expect(system_check.check?).to eq(false)
    end

    it 'returns false when key is not valid RSA key' do
      invalid_key = OpenSSL::PKey::RSA.new(1024).to_s.delete("\n")
      expect(Rails.application.secrets).to receive(:ci_jwt_signing_key).and_return(invalid_key)

      expect(system_check.check?).to eq(false)
    end

    it 'returns true when key is valid RSA key' do
      valid_key = OpenSSL::PKey::RSA.new(1024).to_s
      expect(Rails.application.secrets).to receive(:ci_jwt_signing_key).and_return(valid_key)

      expect(system_check.check?).to eq(true)
    end
  end
end
