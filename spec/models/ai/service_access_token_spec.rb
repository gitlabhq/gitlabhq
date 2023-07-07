# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::ServiceAccessToken, type: :model, feature_category: :application_performance do
  describe '#token' do
    let(:token_value) { 'Abc' }

    it 'is encrypted' do
      subject.token = token_value

      aggregate_failures do
        expect(subject.encrypted_token_iv).to be_present
        expect(subject.encrypted_token).to be_present
        expect(subject.encrypted_token).not_to eq(token_value)
        expect(subject.token).to eq(token_value)
      end
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:category) }
    end
  end
end
