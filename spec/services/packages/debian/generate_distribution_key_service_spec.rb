# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GenerateDistributionKeyService, feature_category: :package_registry do
  let(:params) { {} }

  subject { described_class.new(params: params) }

  let(:response) { subject.execute }

  it 'returns an Hash', :aggregate_failures do
    expect(GPGME::Ctx).to receive(:new).with(armor: true, offline: true).and_call_original
    expect(User).to receive(:random_password).with(no_args).and_call_original

    payload = response.payload
    expect(response).to be_a ServiceResponse
    expect(payload.keys).to contain_exactly(:private_key, :public_key, :fingerprint, :passphrase)
    expect(payload[:private_key]).to start_with('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(payload[:public_key]).to start_with('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(payload[:fingerprint].length).to eq(40)
    expect(payload[:passphrase].length).to be > 10
  end

  context 'with invalid passphrase parameter' do
    let(:params) { { passphrase: "k\n%pubring /tmp/file" } }

    it 'returns the error', :aggregate_failures do
      expect(GPGME::Ctx).not_to receive(:new)
      expect(response).to be_error.and have_attributes(
        message: 'Passphrase contains invalid characters',
        reason: :invalid_passphrase
      )
    end
  end
end
