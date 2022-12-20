# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable::PartitionedFilter, :aggregate_failures, feature_category: :continuous_integration do
  before do
    create_tables(<<~SQL)
      CREATE TABLE _test_ci_jobs_metadata (
        id serial NOT NULL,
        partition_id int NOT NULL DEFAULT 10,
        name text,
        PRIMARY KEY (id, partition_id)
      ) PARTITION BY LIST(partition_id);

      CREATE TABLE _test_ci_jobs_metadata_1
        PARTITION OF _test_ci_jobs_metadata
        FOR VALUES IN (10);
    SQL
  end

  let(:model) do
    Class.new(Ci::ApplicationRecord) do
      include Ci::Partitionable::PartitionedFilter

      self.primary_key = :id
      self.table_name = :_test_ci_jobs_metadata

      def self.name
        'TestCiJobMetadata'
      end
    end
  end

  let!(:record) { model.create! }

  let(:where_filter) do
    /WHERE "_test_ci_jobs_metadata"."id" = #{record.id} AND "_test_ci_jobs_metadata"."partition_id" = 10/
  end

  describe '#save' do
    it 'uses id and partition_id' do
      record.name = 'test'
      recorder = ActiveRecord::QueryRecorder.new { record.save! }

      expect(recorder.log).to include(where_filter)
      expect(record.name).to eq('test')
    end
  end

  describe '#update' do
    it 'uses id and partition_id' do
      recorder = ActiveRecord::QueryRecorder.new { record.update!(name: 'test') }

      expect(recorder.log).to include(where_filter)
      expect(record.name).to eq('test')
    end
  end

  describe '#delete' do
    it 'uses id and partition_id' do
      recorder = ActiveRecord::QueryRecorder.new { record.delete }

      expect(recorder.log).to include(where_filter)
      expect(model.count).to be_zero
    end
  end

  describe '#destroy' do
    it 'uses id and partition_id' do
      recorder = ActiveRecord::QueryRecorder.new { record.destroy! }

      expect(recorder.log).to include(where_filter)
      expect(model.count).to be_zero
    end
  end

  def create_tables(table_sql)
    Ci::ApplicationRecord.connection.execute(table_sql)
  end
end
