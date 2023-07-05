# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Logger do
  describe '.capture_exception' do
    let(:exception) { RuntimeError.new('boom') }
    let(:payload) { { foo: '123' } }
    let(:log_entry) { { message: 'boom', context: payload } }

    it 'calls Gitlab::ErrorTracking::Logger.error with formatted log entry' do
      expect_next_instance_of(Gitlab::ErrorTracking::LogFormatter) do |log_formatter|
        expect(log_formatter).to receive(:generate_log).with(exception, payload).and_return(log_entry)
      end

      expect(described_class).to receive(:error).with(log_entry)

      described_class.capture_exception(exception, **payload)
    end
  end
end
