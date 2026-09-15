# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropCiBuildRuntimeEnvironments, feature_category: :runner_core do
  let(:connection) { described_class.new.connection }

  describe '#up' do
    it 'drops the table' do
      migrate!

      expect(connection.table_exists?(:ci_build_runtime_environments)).to be(false)
    end
  end

  describe '#down', :aggregate_failures do
    before do
      migrate!
      schema_migrate_down!
    end

    it 'recreates the table with correct structure' do
      expect(connection.table_exists?(:ci_build_runtime_environments)).to be(true)
    end

    it 'recreates the composite primary key' do
      expect(connection.primary_key(:ci_build_runtime_environments)).to contain_exactly('build_id', 'partition_id')
    end

    it 'recreates all columns' do
      column_names = connection.columns(:ci_build_runtime_environments).map(&:name)

      expect(column_names).to contain_exactly(
        'build_id', 'partition_id', 'runtime_environment_id',
        'runner_machine_id', 'project_id', 'suspend_on_success', 'suspend_on_failure'
      )
    end

    it 'recreates the indexes' do
      index_names = connection.indexes(:ci_build_runtime_environments).map(&:name)

      expect(index_names).to include(
        'index_ci_build_runtime_envs_on_runtime_environment_id',
        'index_ci_build_runtime_envs_on_runner_machine_id',
        'index_ci_build_runtime_envs_on_project_id'
      )
    end
  end
end
