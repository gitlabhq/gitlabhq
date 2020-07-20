# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::BaseService do
  describe '#compose_response' do
    let(:project) { double('project') }
    let(:user) { double('user') }
    let(:service) { described_class.new(project, user) }

    it 'returns bad_request error when response has an error key' do
      data = { error: 'Unexpected Error' }

      result = service.send(:compose_response, data)

      expect(result[:status]).to be(:error)
      expect(result[:message]).to be('Unexpected Error')
      expect(result[:http_status]).to be(:bad_request)
    end

    it 'returns server error when response has missing key error_type' do
      data = { error: 'Unexpected Error', error_type: ErrorTracking::ProjectErrorTrackingSetting::SENTRY_API_ERROR_TYPE_MISSING_KEYS }

      result = service.send(:compose_response, data)

      expect(result[:status]).to be(:error)
      expect(result[:message]).to be('Unexpected Error')
      expect(result[:http_status]).to be(:internal_server_error)
    end

    it 'returns no content when response is nil' do
      data = nil

      result = service.send(:compose_response, data)

      expect(result[:status]).to be(:error)
      expect(result[:message]).to be('Not ready. Try again later')
      expect(result[:http_status]).to be(:no_content)
    end

    context 'when result has no errors key' do
      let(:data) { { thing: :cat } }

      it 'raises NotImplementedError' do
        expect { service.send(:compose_response, data) }
          .to raise_error(NotImplementedError)
      end

      context 'when parse_response is implemented' do
        before do
          expect(service).to receive(:parse_response) do |response|
            { animal: response[:thing] }
          end
        end

        it 'returns successful response' do
          result = service.send(:compose_response, data)

          expect(result[:animal]).to eq(:cat)
          expect(result[:status]).to eq(:success)
        end

        it 'returns successful response with changes from passed block' do
          result = service.send(:compose_response, data) do
            data[:thing] = :fish
          end

          expect(result[:animal]).to eq(:fish)
          expect(result[:status]).to eq(:success)
        end
      end
    end
  end
end
