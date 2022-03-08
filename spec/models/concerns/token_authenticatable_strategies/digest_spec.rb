# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatableStrategies::Digest do
  let(:model) { class_double('Project') }
  let(:options) { { digest: true } }

  subject(:strategy) do
    described_class.new(model, 'some_field', options)
  end

  describe '#token_fields' do
    it 'includes the digest field' do
      expect(strategy.token_fields).to contain_exactly('some_field', 'some_field_digest')
    end
  end
end
