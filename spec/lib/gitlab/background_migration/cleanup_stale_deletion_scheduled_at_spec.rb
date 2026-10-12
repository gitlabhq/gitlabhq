# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupStaleDeletionScheduledAt, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_details) { table(:namespace_details) }

  let!(:organization) { organizations.create!(name: 'default', path: 'default') }

  let(:scheduled_time) { 3.days.ago }

  let!(:deletion_scheduled_ns) { create_namespace('group-deletion-scheduled', state: 2) }
  let!(:deletion_in_progress_ns) { create_namespace('group-deletion-in-progress', state: 4) }
  let!(:stale_ns) { create_namespace('group-stale', state: 0) }
  let!(:null_ns) { create_namespace('group-null', state: 0) }

  before do
    # valid rows: namespace state machine keeps the column in sync
    namespace_details.create!(namespace_id: deletion_scheduled_ns.id, deletion_scheduled_at: scheduled_time)
    namespace_details.create!(namespace_id: deletion_in_progress_ns.id, deletion_scheduled_at: scheduled_time)

    # stale row: namespace is not being deleted but the column was never cleared.
    # update_column bypasses the state machine to simulate legacy data.
    namespace_details.create!(namespace_id: stale_ns.id).update_column(:deletion_scheduled_at, scheduled_time)

    namespace_details.create!(namespace_id: null_ns.id)
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: namespace_details.minimum(:namespace_id),
      end_id: namespace_details.maximum(:namespace_id),
      batch_table: :namespace_details,
      batch_column: :namespace_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  it 'clears deletion_scheduled_at only on rows whose namespace is not being deleted' do
    perform_migration

    expect(namespace_details.find_by(namespace_id: stale_ns.id).deletion_scheduled_at).to be_nil

    expect(namespace_details.find_by(namespace_id: deletion_scheduled_ns.id).deletion_scheduled_at)
      .to be_within(1.second).of(scheduled_time)
    expect(namespace_details.find_by(namespace_id: deletion_in_progress_ns.id).deletion_scheduled_at)
      .to be_within(1.second).of(scheduled_time)
    expect(namespace_details.find_by(namespace_id: null_ns.id).deletion_scheduled_at).to be_nil
  end

  it 'only iterates rows with deletion_scheduled_at set' do
    scoped = described_class.new(
      batch_table: :namespace_details,
      batch_column: :namespace_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).filter_batch(namespace_details.all)

    expect(scoped.pluck(:namespace_id))
      .to contain_exactly(deletion_scheduled_ns.id, deletion_in_progress_ns.id, stale_ns.id)
  end

  def create_namespace(name, state:)
    namespaces.create!(
      name: name,
      path: name,
      type: 'Group',
      organization_id: organization.id,
      state: state
    )
  end
end
