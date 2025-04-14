# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Snippets::HttpResponseMap, feature_category: :source_code_management do
  describe '.status_for' do
    context 'when reason is in the map' do
      it 'returns the corresponding HTTP status', :aggregate_failures do
        expect(described_class.status_for(:success)).to eq(200)
        expect(described_class.status_for(:error)).to eq(400)
        expect(described_class.status_for(:invalid_params_error)).to eq(422)
        expect(described_class.status_for(:failed_to_create_error)).to eq(400)
        expect(described_class.status_for(:failed_to_update_error)).to eq(400)
      end
    end

    context 'when reason is not in the map' do
      it 'returns 500 and logs a structured warning' do
        some_unknown_reason = :some_unknown_reason

        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: described_class::UNHANDLED,
          reason: some_unknown_reason.inspect
        )

        expect(described_class.status_for(some_unknown_reason)).to eq(500)
      end
    end
  end
end
