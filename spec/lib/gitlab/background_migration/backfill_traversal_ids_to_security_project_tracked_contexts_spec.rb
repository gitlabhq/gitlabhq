# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillTraversalIdsToSecurityProjectTrackedContexts, feature_category: :vulnerability_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:tracked_contexts) { table(:security_project_tracked_contexts, database: :sec) }
  let(:args) do
    min, max = tracked_contexts.pick('MIN(id)', 'MAX(id)')
    {
      start_id: min,
      end_id: max,
      batch_table: 'security_project_tracked_contexts',
      batch_column: 'id',
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ::SecApplicationRecord.connection
    }
  end

  let(:organization) { organizations.create!(name: 'Organization', path: 'organization') }
  let!(:group_namespace) do
    namespaces.create!(
      name: 'gitlab-org',
      path: 'gitlab-org',
      type: 'Group',
      organization_id: organization.id
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:other_group_namespace) do
    namespaces.create!(
      name: 'gitlab-com',
      path: 'gitlab-com',
      type: 'Group',
      organization_id: organization.id
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:sub_group_namespace) do
    namespaces.create!(
      name: 'security',
      path: 'security',
      type: 'Group',
      parent_id: group_namespace.id,
      organization_id: organization.id
    ).tap { |namespace| namespace.update!(traversal_ids: [group_namespace.id, namespace.id]) }
  end

  let!(:project) { create_project('gitlab', group_namespace) }
  let!(:other_project) { create_project('www-gitlab-com', other_group_namespace) }
  let!(:nested_project) { create_project('gitlab-secure', sub_group_namespace) }

  subject(:perform_migration) { described_class.new(**args).perform }

  before do
    create_tracked_context(project: project)
    create_tracked_context(project: project, context_name: 'release')
    create_tracked_context(project: other_project)
    create_tracked_context(project: nested_project)
  end

  it 'backfills traversal_ids', :aggregate_failures do
    perform_migration

    expect_every_context_to_match_its_namespace
  end

  it 'repairs a populated row that disagrees with its namespace' do
    stale = create_tracked_context(
      project: project,
      context_name: 'stale',
      traversal_ids: [other_group_namespace.id]
    )

    perform_migration

    expect(tracked_contexts.find(stale.id).traversal_ids).to eq([group_namespace.id])
  end

  # The sync path writes the same column. A row it moves between the pluck and the update no
  # longer matches the plucked value, so compare-and-set must leave the newer value in place.
  it 'does not overwrite a value written after the batch was read' do
    tracked_context = tracked_contexts.find_by(project_id: project.id, context_name: 'main')
    synced_traversal_ids = [other_group_namespace.id]

    allow(described_class::Project).to receive(:traversal_ids_by_project).and_wrap_original do |original, *args|
      original.call(*args).tap do
        tracked_contexts.where(id: tracked_context.id).update_all(traversal_ids: synced_traversal_ids)
      end
    end

    perform_migration

    expect(tracked_contexts.find(tracked_context.id).traversal_ids).to eq(synced_traversal_ids)
  end

  it 'leaves tracked contexts outside the batch range untouched' do
    excluded = create_tracked_context(project: nested_project, context_name: 'excluded')

    described_class.new(**args.merge(end_id: excluded.id - 1)).perform

    expect(tracked_contexts.find(excluded.id).traversal_ids).to eq([])
  end

  # `perform_migration` is a memoized subject, so a second call would not re-run anything.
  it 'is idempotent', :aggregate_failures do
    2.times { described_class.new(**args).perform }

    expect_every_context_to_match_its_namespace
  end

  it 'skips a tracked context whose project no longer exists' do
    orphan = create_tracked_context(project_id: non_existing_record_id, context_name: 'orphan')

    described_class.new(**args.merge(start_id: orphan.id, end_id: orphan.id)).perform

    expect(tracked_contexts.find(orphan.id).traversal_ids).to eq([])
  end

  it 'skips a sub-batch that no longer has any rows' do
    job = described_class.new(**args)
    allow(job).to receive(:each_sub_batch).and_yield(tracked_contexts.none)

    expect { job.perform }.not_to change { tracked_contexts.order(:id).pluck(:traversal_ids) }
  end

  def expect_every_context_to_match_its_namespace
    tracked_contexts.find_each do |tracked_context|
      project_record = projects.find(tracked_context.project_id)
      namespace = namespaces.find(project_record.namespace_id)

      expect(tracked_context.traversal_ids).to eq(namespace.traversal_ids)
    end
  end

  def create_tracked_context(context_name: 'main', traversal_ids: [], project: nil, project_id: nil)
    tracked_contexts.create!(
      project_id: project_id || project.id,
      context_name: context_name,
      context_type: 1,
      state: 2,
      is_default: context_name == 'main',
      traversal_ids: traversal_ids,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  def create_project(name, group)
    project_namespace = namespaces.create!(
      name: name,
      path: name,
      type: 'Project',
      organization_id: organization.id
    )

    projects.create!(
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id,
      name: name,
      path: name
    )
  end
end
