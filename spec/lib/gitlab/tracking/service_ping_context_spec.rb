# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::ServicePingContext do
  describe '#init' do
    using RSpec::Parameterized::TableSyntax

    context 'with valid configuration' do
      where(:data_source, :event) do
        :redis     | 'some_event'
        :redis_hll | 'some_event'
      end

      with_them do
        it 'does not raise errors' do
          expect { described_class.new(data_source: data_source, event: event) }.not_to raise_error
        end
      end
    end

    context 'with invalid configuration' do
      where(:data_source, :event) do
        :redis     | nil
        :redis_hll | nil
        :random    | 'some_event'
      end

      with_them do
        subject(:new_instance) { described_class.new(data_source: data_source, event: event) }

        it 'does not raise errors' do
          expect { new_instance }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#to_context' do
    context 'for redis_hll data source' do
      let(:context_instance) { described_class.new(data_source: :redis_hll, event: 'sample_event') }

      it 'contains event_name' do
        expect(context_instance.to_context.to_json.dig(:data, :event_name)).to eq('sample_event')
      end
    end

    context 'for redis data source' do
      let(:context_instance) { described_class.new(data_source: :redis, event: 'some_event') }

      it 'contains event_name' do
        expect(context_instance.to_context.to_json.dig(:data, :event_name)).to eq('some_event')
      end
    end
  end
end
