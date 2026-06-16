# frozen_string_literal: true

require 'spec_helper'
require './keeps/cleanup_unused_indexes/instance_cluster_mapper'

RSpec.describe Keeps::CleanupUnusedIndexes::InstanceClusterMapper, feature_category: :database do
  subject(:mapper) { described_class.new }

  def stub_connections(connections)
    # connections => { 'main' => [:gitlab_main, ...], 'ci' => [:gitlab_ci], ... }
    db_infos = connections.to_h do |name, schemas|
      info = instance_double(Gitlab::Database::DatabaseConnectionInfo, name: name, gitlab_schemas: schemas)
      [name.to_sym, info]
    end

    allow(Gitlab::Database).to receive(:all_database_connections).and_return(db_infos)
  end

  describe '#for_schema' do
    context 'with the canonical multi-database configuration' do
      before do
        stub_connections(
          'main' => [:gitlab_main, :gitlab_main_clusterwide, :gitlab_main_cell, :gitlab_pm, :gitlab_shared],
          'ci' => [:gitlab_ci],
          'sec' => [:gitlab_sec]
        )
      end

      it "returns 'patroni' for a schema owned by the main connection" do
        expect(mapper.for_schema('gitlab_main')).to eq('patroni')
      end

      it "returns 'patroni' for any schema owned by main (e.g. gitlab_pm, gitlab_main_cell)", :aggregate_failures do
        expect(mapper.for_schema('gitlab_pm')).to eq('patroni')
        expect(mapper.for_schema('gitlab_main_cell')).to eq('patroni')
      end

      it "returns 'patroni-ci' for gitlab_ci" do
        expect(mapper.for_schema('gitlab_ci')).to eq('patroni-ci')
      end

      it "returns 'patroni-sec' for gitlab_sec" do
        expect(mapper.for_schema('gitlab_sec')).to eq('patroni-sec')
      end

      it "falls back to 'patroni' for an unknown gitlab_schema" do
        expect(mapper.for_schema('gitlab_some_imaginary_schema')).to eq('patroni')
      end

      it "falls back to 'patroni' when gitlab_schema is nil" do
        expect(mapper.for_schema(nil)).to eq('patroni')
      end
    end

    it 'memoises results per gitlab_schema' do
      stub_connections('main' => [:gitlab_main], 'ci' => [:gitlab_ci])

      mapper.for_schema('gitlab_main')
      mapper.for_schema('gitlab_main')
      mapper.for_schema('gitlab_main')

      expect(Gitlab::Database).to have_received(:all_database_connections).once
    end
  end
end
