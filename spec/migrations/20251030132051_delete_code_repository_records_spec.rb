# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteCodeRepositoryRecords, migration: :gitlab_main, feature_category: :global_search do
  let(:code_repositories) { table(:p_ai_active_context_code_repositories) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) do
    table(:namespaces).create!(name: 'namespace', path: 'namespace', organization_id: organization.id)
  end

  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  before do
    # The table is partitioned by project_id with a partition size of 2,000,000.
    # Create a partition for the test data.
    ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.p_ai_active_context_code_repositories_1
      PARTITION OF p_ai_active_context_code_repositories
      FOR VALUES FROM (1) TO (2000000);
    SQL

    code_repositories.create!(project_id: project.id, metadata: {})
    code_repositories.create!(project_id: project.id, metadata: {})
  end

  describe '#up' do
    it 'deletes all code repository records' do
      expect { migrate! }.to change { code_repositories.count }.from(2).to(0)
    end
  end
end
