# frozen_string_literal: true

require 'spec_helper'
# this needs the schema to be before we introduce the not null constraint on routes#namespace_id
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::BackgroundMigration::IssuesInternalIdScopeUpdater, feature_category: :team_planning do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:internal_ids) { table(:internal_ids) }

  let(:gr1) { namespaces.create!(name: 'batchtest1', type: 'Group', path: 'space1') }
  let(:gr2) { namespaces.create!(name: 'batchtest2', type: 'Group', parent_id: gr1.id, path: 'space2') }

  let(:pr_nmsp1) { namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', parent_id: gr1.id) }
  let(:pr_nmsp2) { namespaces.create!(name: 'proj2', path: 'proj2', type: 'Project', parent_id: gr1.id) }
  let(:pr_nmsp3) { namespaces.create!(name: 'proj3', path: 'proj3', type: 'Project', parent_id: gr2.id) }
  let(:pr_nmsp4) { namespaces.create!(name: 'proj4', path: 'proj4', type: 'Project', parent_id: gr2.id) }
  let(:pr_nmsp5) { namespaces.create!(name: 'proj5', path: 'proj5', type: 'Project', parent_id: gr2.id) }
  let(:pr_nmsp6) { namespaces.create!(name: 'proj6', path: 'proj6', type: 'Project', parent_id: gr2.id) }

  # rubocop:disable Layout/LineLength
  let(:p1) { projects.create!(name: 'proj1', path: 'proj1', namespace_id: gr1.id, project_namespace_id: pr_nmsp1.id) }
  let(:p2) { projects.create!(name: 'proj2', path: 'proj2', namespace_id: gr1.id, project_namespace_id: pr_nmsp2.id) }
  let(:p3) { projects.create!(name: 'proj3', path: 'proj3', namespace_id: gr2.id, project_namespace_id: pr_nmsp3.id) }
  let(:p4) { projects.create!(name: 'proj4', path: 'proj4', namespace_id: gr2.id, project_namespace_id: pr_nmsp4.id) }
  let(:p5) { projects.create!(name: 'proj5', path: 'proj5', namespace_id: gr2.id, project_namespace_id: pr_nmsp5.id) }
  let(:p6) { projects.create!(name: 'proj6', path: 'proj6', namespace_id: gr2.id, project_namespace_id: pr_nmsp6.id) }
  # rubocop:enable Layout/LineLength

  # a project that already is covered by a record for its namespace. This should result in no new record added and
  # project related record deleted
  let!(:issues_internal_ids_p1) { internal_ids.create!(project_id: p1.id, usage: 0, last_value: 100) }
  let!(:issues_internal_ids_pr_nmsp1) { internal_ids.create!(namespace_id: pr_nmsp1.id, usage: 0, last_value: 111) }

  # project records that do not have a corresponding namespace record. This should result 2 new records
  # scoped to corresponding project namespaces being added and the project related records being deleted.
  let!(:issues_internal_ids_p2) { internal_ids.create!(project_id: p2.id, usage: 0, last_value: 200) }
  let!(:issues_internal_ids_p3) { internal_ids.create!(project_id: p3.id, usage: 0, last_value: 300) }

  # a project record on a different usage, should not be affected by the migration and
  # no new record should be created for this case
  let!(:issues_internal_ids_p4) { internal_ids.create!(project_id: p4.id, usage: 4, last_value: 400) }

  # a project namespace scoped record without a corresponding project record, should not affect anything.
  let!(:issues_internal_ids_pr_nmsp5) { internal_ids.create!(namespace_id: pr_nmsp5.id, usage: 0, last_value: 500) }

  # a record scoped to a group, should not affect anything.
  let!(:issues_internal_ids_gr1) { internal_ids.create!(namespace_id: gr1.id, usage: 0, last_value: 600) }

  # a project that is covered by a record for its namespace, but has a higher last_value, due to updates during rolling
  # deploy for instance, see https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8548
  let!(:issues_internal_ids_p6) { internal_ids.create!(project_id: p6.id, usage: 0, last_value: 111) }
  let!(:issues_internal_ids_pr_nmsp6) { internal_ids.create!(namespace_id: pr_nmsp6.id, usage: 0, last_value: 100) }

  subject(:perform_migration) do
    described_class.new(
      start_id: internal_ids.minimum(:id),
      end_id: internal_ids.maximum(:id),
      batch_table: :internal_ids,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'backfills internal_ids records and removes related project records', :aggregate_failures do
    perform_migration

    expected_recs = [pr_nmsp1.id, pr_nmsp2.id, pr_nmsp3.id, pr_nmsp5.id, gr1.id, pr_nmsp6.id]

    # all namespace scoped records for issues(0) usage
    expect(internal_ids.where.not(namespace_id: nil).where(usage: 0).count).to eq(6)
    # all namespace_ids for issues(0) usage
    expect(internal_ids.where.not(namespace_id: nil).where(usage: 0).pluck(:namespace_id)).to match_array(expected_recs)
    # this is the record with usage: 4
    expect(internal_ids.where.not(project_id: nil).count).to eq(1)
    # no project scoped records for issues usage left
    expect(internal_ids.where.not(project_id: nil).where(usage: 0).count).to eq(0)

    # the case when the project_id scoped record had the higher last_value,
    # see `issues_internal_ids_p6` and issues_internal_ids_pr_nmsp6 definitions above
    expect(internal_ids.where(namespace_id: pr_nmsp6.id).first.last_value).to eq(111)

    # the case when the namespace_id scoped record had the higher last_value,
    # see `issues_internal_ids_p1` and issues_internal_ids_pr_nmsp1 definitions above.
    expect(internal_ids.where(namespace_id: pr_nmsp1.id).first.last_value).to eq(111)
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
