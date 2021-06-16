# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::ContextPayloadProcessor do
  describe '.call' do
    let(:required_options) do
      {
        configuration: Raven.configuration,
        context: Raven.context,
        breadcrumbs: Raven.breadcrumbs
      }
    end

    let(:event) { Raven::Event.new(required_options.merge(payload)) }
    let(:result_hash) { described_class.call(event).to_hash }

    before do
      allow_next_instance_of(Gitlab::ErrorTracking::ContextPayloadGenerator) do |generator|
        allow(generator).to receive(:generate).and_return(
          user: { username: 'root' },
          tags: { locale: 'en', program: 'test', feature_category: 'feature_a', correlation_id: 'cid' },
          extra: { some_info: 'info' }
        )
      end
    end

    let(:payload) do
      {
        user: { ip_address: '127.0.0.1' },
        tags: { priority: 'high' },
        extra: { sidekiq: { class: 'SomeWorker', args: ['[FILTERED]', 1, 2] } }
      }
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
