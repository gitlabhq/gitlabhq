# frozen_string_literal: true

require 'fast_spec_helper'

ActiveSupport::Dependencies.autoload_paths << 'app/services'

RSpec.describe ServiceResponse do
  describe '.success' do
    it 'creates a successful response without a message' do
      expect(described_class.success).to be_success
    end

    it 'creates a successful response with a message' do
      response = described_class.success(message: 'Good orange')

      expect(response).to be_success
      expect(response.message).to eq('Good orange')
    end

    it 'creates a successful response with payload' do
      response = described_class.success(payload: { good: 'orange' })

      expect(response).to be_success
      expect(response.payload).to eq(good: 'orange')
    end

    it 'creates a successful response with default HTTP status' do
      response = described_class.success

      expect(response).to be_success
      expect(response.http_status).to eq(:ok)
    end

    it 'creates a successful response with custom HTTP status' do
      response = described_class.success(http_status: 204)

      expect(response).to be_success
      expect(response.http_status).to eq(204)
    end
  end

  describe '.error' do
    it 'creates a failed response without HTTP status' do
      response = described_class.error(message: 'Bad apple')

      expect(response).to be_error
      expect(response.message).to eq('Bad apple')
    end

    it 'creates a failed response with HTTP status' do
      response = described_class.error(message: 'Bad apple', http_status: 400)

      expect(response).to be_error
      expect(response.message).to eq('Bad apple')
      expect(response.http_status).to eq(400)
    end

    it 'creates a failed response with payload' do
      response = described_class.error(message: 'Bad apple',
                                       payload: { bad: 'apple' })

      expect(response).to be_error
      expect(response.message).to eq('Bad apple')
      expect(response.payload).to eq(bad: 'apple')
    end
  end

  describe '#success?' do
    it 'returns true for a successful response' do
      expect(described_class.success.success?).to eq(true)
    end

    it 'returns false for a failed response' do
      expect(described_class.error(message: 'Bad apple').success?).to eq(false)
    end
  end

  describe '#error?' do
    it 'returns false for a successful response' do
      expect(described_class.success.error?).to eq(false)
    end

    it 'returns true for a failed response' do
      expect(described_class.error(message: 'Bad apple').error?).to eq(true)
    end
  end

  describe '#errors' do
    it 'returns an empty array for a successful response' do
      expect(described_class.success.errors).to be_empty
    end

    it 'returns an array with a correct message for an error response' do
      expect(described_class.error(message: 'error message').errors).to eq(['error message'])
    end
  end
end
