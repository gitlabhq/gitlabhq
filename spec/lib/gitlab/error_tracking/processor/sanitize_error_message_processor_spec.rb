# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::SanitizeErrorMessageProcessor, :sentry do
  describe '.call' do
    let(:exception) { StandardError.new('raw error') }
    let(:event) { Raven::Event.from_exception(exception, raven_required_options) }
    let(:result_hash) { described_class.call(event).to_hash }
    let(:raven_required_options) do
      {
        configuration: Raven.configuration,
        context: Raven.context,
        breadcrumbs: Raven.breadcrumbs
      }
    end

    it 'cleans the exception message' do
      expect(Gitlab::Sanitizers::ExceptionMessage).to receive(:clean).with('StandardError', 'raw error').and_return('cleaned')

      expect(result_hash[:exception][:values].first).to include(
        type: 'StandardError',
        value: 'cleaned'
      )
    end

    context 'when event is invalid' do
      let(:event) { instance_double('Raven::Event', to_hash: { invalid: true }) }

      it 'does nothing' do
        extracted_exception = instance_double('Raven::SingleExceptionInterface', value: nil)
        allow(described_class).to receive(:extract_exceptions_from).and_return([extracted_exception])

        expect(Gitlab::Sanitizers::ExceptionMessage).not_to receive(:clean)
        expect(result_hash).to eq(invalid: true)
      end
    end
  end
end
