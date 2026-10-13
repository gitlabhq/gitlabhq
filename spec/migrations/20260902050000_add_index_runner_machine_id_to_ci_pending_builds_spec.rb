# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AddIndexRunnerMachineIdToCiPendingBuilds, migration: :gitlab_ci,
  feature_category: :continuous_integration do
  let(:index_name) { described_class::INDEX_NAME }

  describe '#up' do
    it 'creates the partial index on runner_machine_id' do
      migrate!

      connection = described_class.new.connection
      expect(connection.index_exists?(:ci_pending_builds, nil, name: index_name)).to be(true)
    end
  end

  describe '#down' do
    it 'removes the partial index on runner_machine_id' do
      migrate!
      schema_migrate_down!

      connection = described_class.new.connection
      expect(connection.index_exists?(:ci_pending_builds, nil, name: index_name)).to be(false)
    end
  end
end
