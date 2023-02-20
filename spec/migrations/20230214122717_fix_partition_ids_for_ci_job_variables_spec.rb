# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixPartitionIdsForCiJobVariables, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:builds) { table(:ci_builds, database: :ci) }
  let(:job_variables) { table(:ci_job_variables, database: :ci) }
  let(:connection) { job_variables.connection }

  around do |example|
    connection.execute "ALTER TABLE #{job_variables.quoted_table_name} DISABLE TRIGGER ALL;"

    example.run
  ensure
    connection.execute "ALTER TABLE #{job_variables.quoted_table_name} ENABLE TRIGGER ALL;"
  end

  before do
    job = builds.create!(partition_id: 100)

    job_variables.insert_all!([
      { job_id: job.id, partition_id: 100, key: 'variable-100' },
      { job_id: job.id, partition_id: 101, key: 'variable-101' }
    ])
  end

  describe '#up', :aggregate_failures do
    context 'when on sass' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'fixes partition_id' do
        expect { migrate! }.not_to raise_error

        expect(job_variables.where(partition_id: 100).count).to eq(2)
        expect(job_variables.where(partition_id: 101).count).to eq(0)
      end
    end

    context 'when on self managed' do
      it 'does not change partition_id' do
        expect { migrate! }.not_to raise_error

        expect(job_variables.where(partition_id: 100).count).to eq(1)
        expect(job_variables.where(partition_id: 101).count).to eq(1)
      end
    end
  end
end
