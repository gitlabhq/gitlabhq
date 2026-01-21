# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::JwtValidator, feature_category: :integrations do
  let_it_be(:installation) { create(:jira_connect_installation) }
  let_it_be(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test') }

  describe '.valid_token_size?' do
    subject { described_class.valid_token_size?(token) }

    shared_examples 'returns true for valid token' do
      it { is_expected.to be true }
    end

    shared_examples 'returns false for invalid token' do
      it { is_expected.to be false }
    end

    context 'with valid JWT token' do
      let(:token) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

      it_behaves_like 'returns true for valid token'
    end

    context 'with invalid JWT token' do
      context 'with nil JWT' do
        let(:token) { nil }

        it_behaves_like 'returns false for invalid token'
      end

      context 'with empty JWT' do
        let(:token) { '' }

        it_behaves_like 'returns false for invalid token'
      end

      context 'with oversized JWT' do
        let(:token) { 'x' * 9.kilobytes }

        it_behaves_like 'returns false for invalid token'
      end
    end
  end

  describe 'MAX_JWT_SIZE constant' do
    it 'is set to 8 kilobytes' do
      expect(described_class::MAX_JWT_SIZE).to eq(8.kilobytes)
    end
  end
end
