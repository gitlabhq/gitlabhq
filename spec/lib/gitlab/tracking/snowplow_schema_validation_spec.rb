# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Snowplow Schema Validation' do
  context 'snowplow events definition' do
    shared_examples 'matches schema' do
      it 'conforms schema json' do
        paths = Dir[Rails.root.join(yaml_path)]

        events = paths.each_with_object([]) do |path, metrics|
          metrics.push(
            YAML.safe_load(File.read(path), aliases: true)
          )
        end

        expect(events).to all match_schema(Rails.root.join('config/events/schema.json'))
      end
    end

    describe 'matches the schema for CE' do
      let(:yaml_path) { 'config/events/*.yml' }

      it_behaves_like 'matches schema'
    end

    describe 'matches the schema for EE' do
      let(:yaml_path) { 'ee/config/events/*.yml' }

      it_behaves_like 'matches schema'
    end
  end
end
