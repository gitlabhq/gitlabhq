# frozen_string_literal: true

require 'fast_spec_helper'

require 're2'

require_relative '../../app/services/service_response'
require_relative '../../lib/gitlab/error_tracking'

RSpec.describe ServiceResponse, feature_category: :shared do
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
    it 'creates an error response without HTTP status' do
      response = described_class.error(message: 'Bad apple')

      expect(response).to be_error
      expect(response.message).to eq('Bad apple')
    end

    it 'creates an error response with HTTP status' do
      response = described_class.error(message: 'Bad apple', http_status: 400)

      expect(response).to be_error
      expect(response.message).to eq('Bad apple')
      expect(response.http_status).to eq(400)
    end

    it 'creates an error response with payload' do
      response = described_class.error(message: 'Bad apple', payload: { bad: 'apple' })

      expect(response).to be_error
      expect(response.message).to eq('Bad apple')
      expect(response.payload).to eq(bad: 'apple')
    end

    it 'creates an error response with a reason' do
      response = described_class.error(message: 'Bad apple', reason: :permission_denied)

      expect(response).to be_error
      expect(response.message).to eq('Bad apple')
      expect(response.reason).to eq(:permission_denied)
    end
  end

  describe '.from_legacy_hash' do
    it 'with a ServiceResponse, returns the argument' do
      response = described_class.success

      expect(described_class.from_legacy_hash(response)).to be(response)
    end

    it 'with a Hash, builds a new ServiceResponse' do
      hash = {
        status: :error,
        message: 'lorem ipsum',
        payload: { foo: 123 }
      }

      result = described_class.from_legacy_hash(hash)

      expect(result.class).to be(described_class)
      expect(result.success?).to be(false)
      expect(result.payload).to match(a_hash_including({ foo: 123 }))
      expect(result.status).to be(:error)
      expect(result.message).to be('lorem ipsum')
      expect(result.http_status).to be_nil
      expect(result.reason).to be_nil
    end

    it 'throws if argument not expected type' do
      expect { described_class.from_legacy_hash(123) }.to raise_error(ArgumentError)
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

  describe '#track_and_raise_exception' do
    context 'when successful' do
      let(:response) { described_class.success }

      it 'returns self' do
        expect(response.track_and_raise_exception).to be response
      end
    end

    context 'when an error' do
      let(:response) { described_class.error(message: 'bang') }

      it 'tracks and raises' do
        expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_exception)
          .with(StandardError.new('bang'), {})

        response.track_and_raise_exception
      end

      it 'allows specification of error class' do
        error = Class.new(StandardError)
        expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_exception)
          .with(error.new('bang'), {})

        response.track_and_raise_exception(as: error)
      end

      it 'allows extra data for tracking' do
        expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_exception)
          .with(StandardError.new('bang'), { foo: 1, bar: 2 })

        response.track_and_raise_exception(foo: 1, bar: 2)
      end
    end
  end

  describe '#track_exception' do
    context 'when successful' do
      let(:response) { described_class.success }

      it 'returns self' do
        expect(response.track_exception).to be response
      end
    end

    context 'when an error' do
      let(:response) { described_class.error(message: 'bang') }

      it 'tracks' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(StandardError.new('bang'), {})

        expect(response.track_exception).to be response
      end

      it 'allows specification of error class' do
        error = Class.new(StandardError)
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(error.new('bang'), {})

        expect(response.track_exception(as: error)).to be response
      end

      it 'allows extra data for tracking' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(StandardError.new('bang'), { foo: 1, bar: 2 })

        expect(response.track_exception(foo: 1, bar: 2)).to be response
      end
    end
  end

  describe '#log_and_raise_exception' do
    context 'when successful' do
      let(:response) { described_class.success }

      it 'returns self' do
        expect(response.log_and_raise_exception).to be response
      end
    end

    context 'when an error' do
      let(:response) { described_class.error(message: 'bang') }

      it 'logs' do
        expect(::Gitlab::ErrorTracking).to receive(:log_and_raise_exception)
          .with(StandardError.new('bang'), {})

        response.log_and_raise_exception
      end

      it 'allows specification of error class' do
        error = Class.new(StandardError)
        expect(::Gitlab::ErrorTracking).to receive(:log_and_raise_exception)
          .with(error.new('bang'), {})

        response.log_and_raise_exception(as: error)
      end

      it 'allows extra data for tracking' do
        expect(::Gitlab::ErrorTracking).to receive(:log_and_raise_exception)
          .with(StandardError.new('bang'), { foo: 1, bar: 2 })

        response.log_and_raise_exception(foo: 1, bar: 2)
      end
    end
  end

  describe '#deconstruct_keys' do
    it 'supports pattern matching' do
      status =
        case described_class.error(message: 'Bad apple')
        in { status: Symbol => status }
          status
        else
          raise
        end
      expect(status).to eq(:error)
    end
  end

  describe '#cause' do
    it 'returns a string inquirer' do
      response = described_class.error(message: 'Bad apple', reason: :invalid_input)
      expect(response.cause).to be_invalid_input
    end
  end
end
