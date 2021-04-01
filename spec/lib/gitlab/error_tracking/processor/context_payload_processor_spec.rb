# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::ContextPayloadProcessor do
  shared_examples 'processing an exception' do
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

  describe '.call' do
    let(:event) { Raven::Event.new(payload) }
    let(:result_hash) { described_class.call(event).to_hash }

    it_behaves_like 'processing an exception'

    context 'when followed by #process' do
      let(:result_hash) { described_class.new.process(described_class.call(event).to_hash) }

      it_behaves_like 'processing an exception'
    end
  end

  describe '#process' do
    let(:event) { Raven::Event.new(payload) }
    let(:result_hash) { described_class.new.process(event.to_hash) }

    context 'with sentry_processors_before_send disabled' do
      before do
        stub_feature_flags(sentry_processors_before_send: false)
      end

      it_behaves_like 'processing an exception'
    end
  end
end
