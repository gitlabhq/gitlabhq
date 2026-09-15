# frozen_string_literal: true

require 'fast_spec_helper'
require 'json_schemer'

RSpec.describe Gitlab::Scheduling::TaskExecutor, feature_category: :global_search do
  let(:includer_class) do
    Class.new do
      include Gitlab::Scheduling::TaskExecutor
    end
  end

  let(:instance) { includer_class.new }

  describe '#dispatch_event' do
    context 'when dispatch_config is nil' do
      it 'does not publish anything' do
        expect(Gitlab::EventStore).not_to receive(:publish)

        instance.dispatch_event(nil)
      end
    end

    context 'with a legacy Event class' do
      let(:event_class) do
        Class.new(Gitlab::EventStore::Event) do
          def schema
            {
              'type' => 'object',
              'properties' => { 'id' => { 'type' => 'integer' } },
              'additionalProperties' => false
            }
          end
        end
      end

      it 'constructs the event via .new(data:)' do
        expect(Gitlab::EventStore).to receive(:publish) do |event|
          expect(event).to be_an_instance_of(event_class)
          expect(event.data[:id]).to eq(5)
        end

        instance.dispatch_event({ event: event_class, data: -> { { id: 5 } } })
      end

      it 'defaults to an empty payload when no :data proc is configured' do
        expect(Gitlab::EventStore).to receive(:publish) do |event|
          expect(event.data).to eq({})
        end

        instance.dispatch_event({ event: event_class })
      end
    end

    context 'with a CloudEvent class' do
      let(:event_class) do
        Class.new(Gitlab::EventStore::CloudEvent) do
          event_category :task_executor_spec
          event_type :dispatched

          def self.build(id: nil)
            build_cloud_event(source: 'instance', subject: 'task_executor_spec/items', event_data: { id: id })
          end

          def data_schema
            {
              'type' => 'object',
              'properties' => { 'id' => { 'type' => %w[integer null] } },
              'additionalProperties' => false
            }
          end
        end
      end

      it 'constructs the event via .build' do
        expect(Gitlab::EventStore).to receive(:publish) do |event|
          expect(event).to be_an_instance_of(event_class)
          expect(event.event_data[:id]).to eq(7)
        end

        instance.dispatch_event({ event: event_class, data: -> { { id: 7 } } })
      end

      it 'builds with no data when no :data proc is configured' do
        expect(Gitlab::EventStore).to receive(:publish) do |event|
          expect(event.event_data[:id]).to be_nil
        end

        instance.dispatch_event({ event: event_class })
      end
    end
  end
end
