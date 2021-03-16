# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::ContextPayloadProcessor do
  subject(:processor) { described_class.new }

  before do
    allow_next_instance_of(Gitlab::ErrorTracking::ContextPayloadGenerator) do |generator|
      allow(generator).to receive(:generate).and_return(
        user: { username: 'root' },
        tags: { locale: 'en', program: 'test', feature_category: 'feature_a', correlation_id: 'cid' },
        extra: { some_info: 'info' }
      )
    end
  end

  it 'merges the context payload into event payload' do
    payload = {
      user: { ip_address: '127.0.0.1' },
      tags: { priority: 'high' },
      extra: { sidekiq: { class: 'SomeWorker', args: ['[FILTERED]', 1, 2] } }
    }

    processor.process(payload)

    expect(payload).to eql(
      user: {
        ip_address: '127.0.0.1',
        username: 'root'
      },
      tags: {
        priority: 'high',
        locale: 'en',
        program: 'test',
        feature_category: 'feature_a',
        correlation_id: 'cid'
      },
      extra: {
        some_info: 'info',
        sidekiq: { class: 'SomeWorker', args: ['[FILTERED]', 1, 2] }
      }
    )
  end
end
