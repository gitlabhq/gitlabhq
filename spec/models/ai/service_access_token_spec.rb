# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::ServiceAccessToken, type: :model, feature_category: :application_performance do
  describe '.expired', :freeze_time do
    let_it_be(:expired_token) { create(:service_access_token, :code_suggestions, :expired) }
    let_it_be(:active_token) {  create(:service_access_token, :code_suggestions, :active) }

    it 'selects all expired tokens' do
      expect(described_class.expired).to match_array([expired_token])
    end
  end

  describe '.active', :freeze_time do
    let_it_be(:expired_token) { create(:service_access_token, :code_suggestions, :expired) }
    let_it_be(:active_token) {  create(:service_access_token, :code_suggestions, :active) }

    it 'selects all active tokens' do
      expect(described_class.active).to match_array([active_token])
    end
  end

  # There is currently only one category, please expand this test when a new category is added.
  describe '.for_category' do
    let(:code_suggestions_token) { create(:service_access_token, :code_suggestions) }
    let(:category) { :code_suggestions }

    it 'only selects tokens from the selected category' do
      expect(described_class.for_category(category)).to match_array([code_suggestions_token])
    end
  end

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
      it { is_expected.to validate_presence_of(:expires_at) }
    end
  end
end
