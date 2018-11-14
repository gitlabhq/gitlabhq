require 'spec_helper'

describe TokenAuthenticatableStrategies::Encrypted do
  let(:model) { double(:model) }
  let(:options) { { fallback: true } }

  subject do
    described_class.new(model, 'some_field', options)
  end

  describe '#find_token_authenticatable' do
  end

  describe '#get_token' do
  end

  describe '#set_token' do
  end
end
