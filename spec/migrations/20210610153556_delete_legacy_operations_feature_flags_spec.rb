# frozen_string_literal: true

require 'spec_helper'

require_migration!('delete_legacy_operations_feature_flags')

RSpec.describe DeleteLegacyOperationsFeatureFlags do
  let(:namespace) { table(:namespaces).create!(name: 'foo', path: 'bar') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let(:issue) { table(:issues).create!(id: 123, project_id: project.id) }
  let(:operations_feature_flags) { table(:operations_feature_flags) }
  let(:operations_feature_flag_scopes) { table(:operations_feature_flag_scopes) }
  let(:operations_strategies) { table(:operations_strategies) }
  let(:operations_scopes) { table(:operations_scopes) }
  let(:operations_feature_flags_issues) { table(:operations_feature_flags_issues) }

  it 'correctly deletes legacy feature flags' do
    # Legacy version of a feature flag - dropped support in GitLab 14.0.
    legacy_flag = operations_feature_flags.create!(project_id: project.id, version: 1, name: 'flag_a', active: true, iid: 1)
    operations_feature_flag_scopes.create!(feature_flag_id: legacy_flag.id, active: true)
    operations_feature_flags_issues.create!(feature_flag_id: legacy_flag.id, issue_id: issue.id)
    # New version of a feature flag.
    new_flag = operations_feature_flags.create!(project_id: project.id, version: 2, name: 'flag_b', active: true, iid: 2)
    new_strategy = operations_strategies.create!(feature_flag_id: new_flag.id, name: 'default')
    operations_scopes.create!(strategy_id: new_strategy.id, environment_scope: '*')
    operations_feature_flags_issues.create!(feature_flag_id: new_flag.id, issue_id: issue.id)

    expect(operations_feature_flags.all.pluck(:version)).to contain_exactly(1, 2)
    expect(operations_feature_flag_scopes.count).to eq(1)
    expect(operations_strategies.count).to eq(1)
    expect(operations_scopes.count).to eq(1)
    expect(operations_feature_flags_issues.all.pluck(:feature_flag_id)).to contain_exactly(legacy_flag.id, new_flag.id)

    migrate!

    # Legacy flag is deleted.
    expect(operations_feature_flags.all.pluck(:version)).to contain_exactly(2)
    # The associated entries of the legacy flag are deleted too.
    expect(operations_feature_flag_scopes.count).to eq(0)
    # The associated entries of the new flag stay instact.
    expect(operations_strategies.count).to eq(1)
    expect(operations_scopes.count).to eq(1)
    expect(operations_feature_flags_issues.all.pluck(:feature_flag_id)).to contain_exactly(new_flag.id)
  end
end
