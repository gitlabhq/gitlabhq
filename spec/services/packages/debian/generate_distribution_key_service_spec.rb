# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GenerateDistributionKeyService do
  let_it_be(:user) { create(:user) }

  let(:params) { {} }

  subject { described_class.new(current_user: user, params: params) }

  let(:response) { subject.execute }

  context 'with a user' do
    it 'returns an Hash', :aggregate_failures do
      expect(GPGME::Ctx).to receive(:new).with(armor: true, offline: true).and_call_original
      expect(User).to receive(:random_password).with(no_args).and_call_original

      expect(response).to be_a Hash
      expect(response.keys).to contain_exactly(:private_key, :public_key, :fingerprint, :passphrase)
      expect(response[:private_key]).to start_with('-----BEGIN PGP PRIVATE KEY BLOCK-----')
      expect(response[:public_key]).to start_with('-----BEGIN PGP PUBLIC KEY BLOCK-----')
      expect(response[:fingerprint].length).to eq(40)
      expect(response[:passphrase].length).to be > 10
    end
  end

  context 'without a user' do
    let(:user) { nil }

    it 'raises an ArgumentError' do
      expect { response }.to raise_error(ArgumentError, 'Please provide a user')
    end
  end
end
