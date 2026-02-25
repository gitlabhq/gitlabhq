# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ExtractDeletionScheduledAtFromStateMetadata, migration: :gitlab_main_org, feature_category: :groups_and_projects do
  let(:namespace_details) { table(:namespace_details) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'default', path: 'default') }

  let(:scheduled_time) { '2026-01-15T10:30:00Z' }

  let!(:ns_with_scheduled_deletion) do
    ns = create_namespace('group-scheduled')
    namespace_details.create!(
      namespace_id: ns.id,
      state_metadata: { deletion_scheduled_at: scheduled_time, deletion_scheduled_by_user_id: 1 }
    )
  end

  let!(:ns_without_scheduled_deletion) do
    ns = create_namespace('group-no-schedule')
    namespace_details.create!(
      namespace_id: ns.id,
      state_metadata: { some_other_key: 'value' }
    )
  end

  let!(:ns_already_extracted) do
    ns = create_namespace('group-already-extracted')
    namespace_details.create!(
      namespace_id: ns.id,
      state_metadata: {},
      deletion_scheduled_at: scheduled_time
    )
  end

  def create_namespace(name)
    namespaces.create!(
      name: name,
      path: name,
      type: 'Group',
      organization_id: organization.id
    )
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  describe '#up' do
    it 'extracts deletion_scheduled_at from state_metadata to the column' do
      migrate!

      record = ns_with_scheduled_deletion.reload
      expect(record.deletion_scheduled_at).to eq(Time.zone.parse(scheduled_time))
    end

    it 'removes deletion_scheduled_at key from state_metadata' do
      migrate!

      record = ns_with_scheduled_deletion.reload
      metadata = record.state_metadata
      expect(metadata).not_to have_key('deletion_scheduled_at')
      expect(metadata).to include('deletion_scheduled_by_user_id' => 1)
    end

    it 'does not modify rows without deletion_scheduled_at in state_metadata' do
      migrate!

      record = ns_without_scheduled_deletion.reload
      metadata = record.state_metadata
      expect(record.deletion_scheduled_at).to be_nil
      expect(metadata).to eq({ 'some_other_key' => 'value' })
    end

    it 'does not modify rows that already have deletion_scheduled_at column set' do
      migrate!

      record = ns_already_extracted.reload
      expect(record.deletion_scheduled_at).to eq(Time.zone.parse(scheduled_time))
    end

    context 'when processing multiple batches' do
      let!(:ns_with_scheduled_deletion_2) do
        ns = create_namespace('group-scheduled-2')
        namespace_details.create!(
          namespace_id: ns.id,
          state_metadata: { deletion_scheduled_at: '2026-02-01T12:00:00Z' }
        )
      end

      let!(:ns_with_scheduled_deletion_3) do
        ns = create_namespace('group-scheduled-3')
        namespace_details.create!(
          namespace_id: ns.id,
          state_metadata: { deletion_scheduled_at: '2026-03-01T08:00:00Z' }
        )
      end

      it 'processes all records across batches' do
        migrate!

        [ns_with_scheduled_deletion, ns_with_scheduled_deletion_2, ns_with_scheduled_deletion_3].each do |record|
          expect(record.reload.deletion_scheduled_at).not_to be_nil
        end
      end
    end
  end

  describe '#down' do
    it 'moves deletion_scheduled_at back into state_metadata' do
      migrate!
      schema_migrate_down!

      record = ns_already_extracted.reload
      metadata = record.state_metadata
      expect(Time.zone.parse(metadata['deletion_scheduled_at'])).to eq(Time.zone.parse(scheduled_time))
    end

    it 'preserves existing state_metadata keys' do
      migrate!
      schema_migrate_down!

      record = ns_with_scheduled_deletion.reload
      metadata = record.state_metadata
      expect(metadata).to include('deletion_scheduled_by_user_id' => 1)
    end

    it 'sets the deletion_scheduled_at column to NULL' do
      migrate!
      schema_migrate_down!

      record = ns_already_extracted.reload
      expect(record.deletion_scheduled_at).to be_nil
    end

    it 'does not modify rows without deletion_scheduled_at' do
      migrate!
      schema_migrate_down!

      record = ns_without_scheduled_deletion.reload
      metadata = record.state_metadata
      expect(record.deletion_scheduled_at).to be_nil
      expect(metadata).not_to have_key('deletion_scheduled_at')
    end
  end
end
