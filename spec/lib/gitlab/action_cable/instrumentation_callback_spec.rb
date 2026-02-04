# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ActionCable::InstrumentationCallback, feature_category: :application_instrumentation do
  describe '.wrapper', :request_store do
    it 'initializes instrumentation data and RequestContext in the inner block' do
      inner_called = false
      described_class.wrapper.call(
        nil,
        -> do
          inner_called = true
          # Verify RequestContext is initialized with instrumentation data
          request_context = ::Gitlab::RequestContext.instance
          expect(request_context.start_thread_cpu_time).not_to be_nil
          expect(request_context.thread_memory_allocations).not_to be_nil
        end
      )
      expect(inner_called).to be true
    end
  end
end
