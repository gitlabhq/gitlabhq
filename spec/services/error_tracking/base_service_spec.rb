# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::BaseService, feature_category: :observability do
  describe '#compose_response' do
    let(:project) { build_stubbed(:project) }
    let(:user) { build_stubbed(:user, id: non_existing_record_id) }
    let(:service) { described_class.new(project, user) }

    it 'returns bad_request error when response has an error key' do
      data = { error: 'Unexpected Error' }

      result = service.send(:compose_response, data)

      expect(result[:status]).to be(:error)
      expect(result[:message]).to be('Unexpected Error')
      expect(result[:http_status]).to be(:bad_request)
    end

    it 'returns server error when response has missing key error_type' do
      data = {
        error: 'Unexpected Error',
        error_type: ErrorTracking::ProjectErrorTrackingSetting::SENTRY_API_ERROR_TYPE_MISSING_KEYS
      }

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
          allow(service).to receive(:parse_response) do |response|
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

        context 'when tracking_event is provided' do
          let(:service) { described_class.new(project, user, tracking_event: :error_tracking_view_list) }

          it_behaves_like 'tracking unique hll events' do
            let(:target_event) { 'error_tracking_view_list' }
            let(:expected_value) { non_existing_record_id }
            let(:request) { service.send(:compose_response, data) }
          end
        end
      end
    end
  end
end
