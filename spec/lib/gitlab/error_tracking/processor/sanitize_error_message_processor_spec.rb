# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::SanitizeErrorMessageProcessor, :sentry do
  describe '.call' do
    let(:exception) { StandardError.new('raw error') }
    let(:result_hash) { described_class.call(event).to_hash }

    shared_examples 'processes the exception' do
      it 'cleans the exception message' do
        expect(Gitlab::Sanitizers::ExceptionMessage).to receive(:clean).with(
          'StandardError', match('raw error')
        ).and_return('cleaned')

        expect(result_hash[:exception][:values].first).to include(
          type: 'StandardError',
          value: 'cleaned'
        )
      end
    end

    context 'with Sentry event' do
      let(:event) { Sentry.get_current_client.event_from_exception(exception) }

      it_behaves_like 'processes the exception'
    end

    context 'with invalid event' do
      let(:event) { instance_double('Sentry::Event', to_hash: { invalid: true }) }

      it 'does nothing' do
        extracted_exception = instance_double('Sentry::SingleExceptionInterface', value: nil)
        allow(described_class).to receive(:extract_exceptions_from).and_return([extracted_exception])

        expect(Gitlab::Sanitizers::ExceptionMessage).not_to receive(:clean)
        expect(result_hash).to eq(invalid: true)
      end
    end
  end
end
