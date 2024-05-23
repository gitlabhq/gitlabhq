# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::ContextPayloadProcessor do
  describe '.call' do
    let(:event) { Sentry::Event.new(configuration: Sentry.configuration) }
    let(:result_hash) { described_class.call(event).to_hash }
    let(:payload) do
      {
        user: { ip_address: '127.0.0.1' },
        tags: { priority: 'high' },
        extra: { sidekiq: { class: 'SomeWorker', args: ['[FILTERED]', 1, 2] } }
      }
    end

    around do |example|
      Sentry.with_scope do |scope|
        scope.set_user(payload[:user])
        scope.set_tags(payload[:tags])
        scope.set_extras(payload[:extra])

        example.run
      end
    end

    before do
      Sentry.get_current_scope.apply_to_event(event)

      allow_next_instance_of(Gitlab::ErrorTracking::ContextPayloadGenerator) do |generator|
        allow(generator).to receive(:generate).and_return(
          user: { username: 'root' },
          tags: { locale: 'en', program: 'test', feature_category: 'feature_a', correlation_id: 'cid' },
          extra: { some_info: 'info' }
        )
      end
    end

    it 'merges the context payload into event payload', :aggregate_failures do
      expect(result_hash[:user]).to include(ip_address: '127.0.0.1', username: 'root')

      expect(result_hash[:tags])
        .to include(priority: 'high',
          locale: 'en',
          program: 'test',
          feature_category: 'feature_a',
          correlation_id: 'cid')

      expect(result_hash[:extra])
        .to include(some_info: 'info',
          sidekiq: { class: 'SomeWorker', args: ['[FILTERED]', 1, 2] })
    end
  end
end
