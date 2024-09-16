# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveNamespaceFromOsTypeSbomComponents, schema: 20240909204952, feature_category: :software_composition_analysis do
  let(:components) { table(:sbom_components) }
  let(:expected) do
    (0...os_prefix_to_purl_type_mapping.size).map { |n| "package-#{n}" }
  end

  let(:os_prefix_to_purl_type_mapping) do
    {
      alma: 10,
      alpine: 9,
      amazon: 10,
      'cbl-mariner': 12,
      centos: 10,
      chainguard: 9,
      debian: 11,
      fedora: 10,
      opensuse: 10,
      'opensuse.leap': 10,
      'opensuse.tumbleweed': 10,
      oracle: 10,
      photon: 10,
      redhat: 10,
      rocky: 10,
      'suse%20linux%20enterprise%20server': 10,
      'suse+linux+enterprise+server': 10,
      ubuntu: 11,
      wolfi: 13
    }.with_indifferent_access.freeze
  end

  before do
    os_prefix_to_purl_type_mapping.each.with_index do |(namespace, purl_type), index|
      components.create!(name: "#{namespace}/package-#{index}", purl_type: purl_type, component_type: 0)
    end
  end

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        start_id: components.first.id,
        end_id: components.last.id,
        batch_table: :sbom_components,
        batch_column: :id,
        sub_batch_size: components.count,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    it 'successfully removes the os namespace prefix' do
      expect(Gitlab::BackgroundMigration::Logger).not_to receive(:warn)

      expect { perform_migration }.not_to raise_error

      expect(components.pluck(:name)).to match_array(expected)
    end

    context 'with existing record in regards to name, purl_type and component_type' do
      before do
        components.create!(name: 'alpine/curl', purl_type: 9, component_type: 0)
        components.create!(name: 'curl', purl_type: 9, component_type: 0)
      end

      it 'rescues valid ActiveRecord::RecordNotUnique errors' do
        expect(Gitlab::BackgroundMigration::Logger).to receive(:warn)

        expect { perform_migration }.not_to raise_error

        expect(components.pluck(:name)).to include(*expected)
        expect(components.pluck(:name)).to include('alpine/curl', 'curl')
      end
    end

    context 'with unexpected ActiveRecord::RecordNotUnique error' do
      before do
        allow(ActiveRecord::RecordNotUnique).to receive(:new).and_wrap_original do |m, *_args|
          m.call('some other not unique error')
        end

        components.create!(name: 'alpine/curl', purl_type: 9, component_type: 0)
        components.create!(name: 'curl', purl_type: 9, component_type: 0)
      end

      it 'raises unknown ActiveRecord::RecordNotUnique errors' do
        expect { perform_migration }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
