# frozen_string_literal: true

require 'fast_spec_helper'
require 'json_schemer'
require 'oj'

RSpec.describe Gitlab::EventStore::Event, feature_category: :shared do
  let(:event_class) { stub_const('TestEvent', Class.new(described_class)) }
  let(:event) { event_class.new(data: data) }
  let(:data) { { 'project_id' => 123, 'project_path' => 'org/the-project' } }

  context 'when schema is not defined' do
    it 'raises an error on initialization' do
      expect { event }.to raise_error(NotImplementedError)
    end
  end

  context 'when schema is defined' do
    before do
      event_class.class_eval do
        def schema
          {
            'required' => ['project_id'],
            'type' => 'object',
            'properties' => {
              'project_id' => { 'type' => 'integer' },
              'project_path' => { 'type' => 'string' }
            }
          }
        end
      end
    end

    it 'returns data with indifferent access' do
      expect(event.data[:project_id]).to eq(123)
      expect(event.data['project_id']).to eq(123)
    end

    describe 'schema validation' do
      context 'when data matches the schema' do
        it 'initializes the event correctly' do
          expect(event.data).to eq(data)
        end
      end

      context 'when required properties are present as well as unknown properties' do
        let(:data) { { 'project_id' => 123, 'unknown_key' => 'unknown_value' } }

        it 'initializes the event correctly' do
          expect(event.data).to eq(data)
        end

        it 'validates schema' do
          expect(event_class.json_schema_valid).to eq(nil)

          event

          expect(event_class.json_schema_valid).to eq(true)
        end
      end

      context 'when some properties are missing' do
        let(:data) { { project_path: 'org/the-project' } }

        it 'expects all properties to be present' do
          expect { event }.to raise_error(Gitlab::EventStore::InvalidEvent, /does not match the defined schema/)
        end
      end

      context 'when data is not a Hash' do
        let(:data) { 123 }

        it 'raises an error' do
          expect { event }.to raise_error(Gitlab::EventStore::InvalidEvent, 'Event data must be a Hash')
        end
      end

      context 'when schema is invalid' do
        before do
          event_class.class_eval do
            def schema
              {
                'required' => ['project_id'],
                'type' => 'object',
                'properties' => {
                  'project_id' => { 'type' => 'int' },
                  'project_path' => { 'type' => 'string ' }
                }
              }
            end
          end
        end

        it 'raises an error' do
          expect(event_class.json_schema_valid).to eq(nil)

          expect { event }.to raise_error(Gitlab::EventStore::InvalidEvent, 'Schema for event TestEvent is invalid')

          expect(event_class.json_schema_valid).to eq(false)
        end

        it 'does not store JSON schema on subclass' do
          expect { event }.to raise_error(Gitlab::EventStore::InvalidEvent)

          expect(event_class.instance_variables).not_to include(:@json_schema)
          expect(described_class.instance_variables).to include(:@json_schema)
        end
      end
    end
  end
end
