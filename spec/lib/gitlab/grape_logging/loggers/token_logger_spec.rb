# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::TokenLogger do
  subject { described_class.new }

  describe ".parameters" do
    let(:token_id) { 1 }
    let(:token_type) { "PersonalAccessToken" }

    describe 'when no token information is available' do
      let(:mock_request) { instance_double(ActionDispatch::Request, 'env', env: {}) }

      it 'returns an empty hash' do
        expect(subject.parameters(mock_request, nil)).to eq({})
      end
    end

    describe 'when token information is available' do
      let(:mock_request) do
        instance_double(ActionDispatch::Request, 'env',
          env: {
            'gitlab.api.token' => { 'token_id': token_id, 'token_type': token_type }
          }
        )
      end

      it 'adds the token information to log parameters' do
        expect(subject.parameters(mock_request, nil)).to eq( { 'token_id': 1, 'token_type': "PersonalAccessToken" })
      end
    end
  end
end
