# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../scripts/internal_events/product_group_renamer'

RSpec.describe ProductGroupRenamer, feature_category: :service_ping do
  let(:renamer) { described_class.new(schema_path, definitions_glob) }

  context 'with real definitions', :aggregate_failures do
    let(:schema_path) { PRODUCT_GROUPS_SCHEMA_PATH }
    let(:definitions_glob) { ALL_METRIC_AND_EVENT_DEFINITIONS_GLOB }

    it 'reads all definitions files' do
      allow(File).to receive(:read).and_call_original

      Gitlab::Tracking::EventDefinition.definitions.each do |event_definition|
        expect(File).to receive(:read).with(event_definition.path)
        expect(File).not_to receive(:write).with(event_definition.path)
      end

      Gitlab::Usage::MetricDefinition.definitions.values.map(&:path).uniq.each do |metric_definition_path|
        expect(File).to receive(:read).with(metric_definition_path)
        expect(File).not_to receive(:write).with(metric_definition_path)
      end

      renamer.rename_product_group('old_name', 'new_name')
    end
  end

  describe '#rename_product_group', :aggregate_failures do
    let(:temp_dir) { Dir.mktmpdir }
    let(:schema_path) { File.join(temp_dir, 'product_groups.json') }
    let(:event_definition_path) { File.join(temp_dir, 'event_definition.yml') }
    let(:metric_definition_path) { File.join(temp_dir, 'metric_definition.yml') }
    let(:event_definition_from_another_group_path) do
      File.join(temp_dir, 'event_definition_from_another_group.yml')
    end

    let(:definitions_glob) { [event_definition_path, metric_definition_path, event_definition_from_another_group_path] }

    before do
      FileUtils.cp_r(File.join('spec/fixtures/scripts/product_group_renamer', '.'), temp_dir)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'renames product group in the schema and the definitions' do
      renamer.rename_product_group('a_group_name', 'a_better_group_name')

      schema_content = File.read(schema_path)

      expect(schema_content).to include('a_better_group_name')
      expect(schema_content).not_to include('a_group_name')
      expect(File.read(event_definition_path)).to include('product_group: a_better_group_name')
      expect(File.read(metric_definition_path)).to include('product_group: a_better_group_name')
      expect(File.read(event_definition_from_another_group_path)).not_to include('product_group: a_better_group_name')
    end
  end
end
