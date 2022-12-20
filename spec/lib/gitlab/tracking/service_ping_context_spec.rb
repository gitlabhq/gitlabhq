# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::ServicePingContext do
  describe '#init' do
    using RSpec::Parameterized::TableSyntax

    context 'with valid configuration' do
      where(:data_source, :event, :key_path) do
        :redis     | nil          | 'counts.some_metric'
        :redis_hll | 'some_event' | nil
      end

      with_them do
        it 'does not raise errors' do
          expect { described_class.new(data_source: data_source, event: event, key_path: key_path) }.not_to raise_error
        end
      end
    end

    context 'with invalid configuration' do
      where(:data_source, :event, :key_path) do
        :redis     | nil          | nil
        :redis     | 'some_event' | nil
        :redis_hll | nil          | nil
        :redis_hll | nil          | 'some key_path'
        :random    | 'some_event' | nil
      end

      with_them do
        subject(:new_instance) { described_class.new(data_source: data_source, event: event, key_path: key_path) }

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
      let(:context_instance) { described_class.new(data_source: :redis, key_path: 'counts.sample_metric') }

      it 'contains event_name' do
        expect(context_instance.to_context.to_json.dig(:data, :key_path)).to eq('counts.sample_metric')
      end
    end
  end
end
