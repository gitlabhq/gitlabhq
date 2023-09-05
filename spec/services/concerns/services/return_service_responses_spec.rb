# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::ReturnServiceResponses, feature_category: :rate_limiting do
  subject(:object) { Class.new { include Services::ReturnServiceResponses }.new }

  let(:message) { 'a delivering message' }
  let(:payload) { 'string payload' }

  describe '#success' do
    it 'returns a ServiceResponse instance' do
      response = object.success(payload)
      expect(response).to be_an(ServiceResponse)
      expect(response).to be_success
      expect(response.message).to be_nil
      expect(response.payload).to eq(payload)
      expect(response.http_status).to eq(:ok)
    end
  end

  describe '#error' do
    it 'returns a ServiceResponse instance' do
      response = object.error(message, :not_found, pass_back: payload)
      expect(response).to be_an(ServiceResponse)
      expect(response).to be_error
      expect(response.message).to eq(message)
      expect(response.payload).to eq(payload)
      expect(response.http_status).to eq(:not_found)
    end
  end
end
