# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::TokenLogger do
  describe ".parameters" do
    let(:token_id) { 1 }
    let(:token_type) { "PersonalAccessToken" }

    subject { described_class.new.parameters(nil, nil) }

    describe 'when no token information is available' do
      before do
        ::Current.token_info = nil
      end

      it 'returns an empty hash' do
        expect(subject).to eq({})
      end
    end

    describe 'when token information is available' do
      before do
        ::Current.token_info = { token_id: token_id, token_type: token_type, token_scopes: [:ai_workflows] }
      end

      it 'adds the token information to log parameters' do
        expect(subject).to eq({ token_id: 1, token_type: "PersonalAccessToken" })
      end
    end

    describe 'when token is available with an OAuth application ID' do
      let(:token_type) { "OAuthAccessToken" }
      let(:token_application_id) { 1000 }

      before do
        ::Current.token_info = {
          token_id: token_id,
          token_type: token_type,
          token_scopes: [:api],
          token_application_id: token_application_id
        }
      end

      it 'adds the token information with OAuth application ID to log parameters' do
        expect(subject).to eq({ token_id: 1, token_type: "OAuthAccessToken", token_application_id: 1000 })
      end
    end
  end
end
