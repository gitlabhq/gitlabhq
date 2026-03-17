# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResetVsaAggregationDataBeforeTheBug, migration: :gitlab_main, feature_category: :value_stream_management do
  let(:aggregations) { table(:analytics_cycle_analytics_aggregations) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:restore_to_time) { Date.parse('2026-02-27').to_time.utc.beginning_of_day }

  let!(:organization) { organizations.create!(name: 'org', path: 'org') }

  let!(:namespace_1) { namespaces.create!(id: 1, name: "n1", path: "p1", organization_id: organization.id) }
  let!(:namespace_2) { namespaces.create!(id: 2, name: "n2", path: "p2", organization_id: organization.id) }
  let!(:namespace_3) { namespaces.create!(id: 3, name: "n3", path: "p3", organization_id: organization.id) }
  let!(:namespace_4) { namespaces.create!(id: 4, name: "n4", path: "p4", organization_id: organization.id) }

  describe '#up' do
    context 'when on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'resets records that have updated_at after restore_to_time' do
        rec1 = aggregations.create!(
          group_id: namespace_1.id,
          last_incremental_issues_updated_at: restore_to_time + 1.hour,
          last_incremental_merge_requests_updated_at: restore_to_time - 1.day,
          last_incremental_issues_id: 100,
          last_incremental_merge_requests_id: 100
        )

        rec2 = aggregations.create!(
          group_id: namespace_2.id,
          last_incremental_issues_updated_at: restore_to_time - 1.day,
          last_incremental_merge_requests_updated_at: restore_to_time + 2.hours,
          last_incremental_issues_id: 200,
          last_incremental_merge_requests_id: 200
        )

        rec3 = aggregations.create!(
          group_id: namespace_3.id,
          last_incremental_issues_updated_at: restore_to_time - 1.day,
          last_incremental_merge_requests_updated_at: restore_to_time - 2.days,
          last_incremental_issues_id: 300,
          last_incremental_merge_requests_id: 300
        )

        rec4 = aggregations.create!(
          group_id: namespace_4.id,
          last_incremental_issues_updated_at: restore_to_time,
          last_incremental_merge_requests_updated_at: restore_to_time,
          last_incremental_issues_id: 400,
          last_incremental_merge_requests_id: 400
        )

        migrate!

        expect(rec1.reload).to have_attributes(
          last_incremental_issues_id: 1,
          last_incremental_issues_updated_at: restore_to_time,
          last_incremental_merge_requests_id: 1,
          last_incremental_merge_requests_updated_at: restore_to_time
        )

        expect(rec2.reload).to have_attributes(
          last_incremental_issues_id: 1,
          last_incremental_issues_updated_at: restore_to_time,
          last_incremental_merge_requests_id: 1,
          last_incremental_merge_requests_updated_at: restore_to_time
        )

        expect(rec3.reload).to have_attributes(
          last_incremental_issues_id: 300,
          last_incremental_issues_updated_at: (restore_to_time - 1.day),
          last_incremental_merge_requests_id: 300,
          last_incremental_merge_requests_updated_at: (restore_to_time - 2.days)
        )

        expect(rec4.reload).to have_attributes(
          last_incremental_issues_id: 1,
          last_incremental_issues_updated_at: restore_to_time,
          last_incremental_merge_requests_id: 1,
          last_incremental_merge_requests_updated_at: restore_to_time
        )
      end

      it 'handles NULL values correctly without reset them' do
        rec = aggregations.create!(
          group_id: namespace_1.id,
          last_incremental_issues_updated_at: nil,
          last_incremental_merge_requests_updated_at: nil,
          last_incremental_issues_id: 500,
          last_incremental_merge_requests_id: 500
        )

        migrate!

        expect(rec.reload).to have_attributes(
          last_incremental_issues_id: 500,
          last_incremental_issues_updated_at: nil,
          last_incremental_merge_requests_id: 500,
          last_incremental_merge_requests_updated_at: nil
        )
      end
    end

    context 'when not on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not change any records' do
        rec1 = aggregations.create!(
          group_id: namespace_1.id,
          last_incremental_issues_updated_at: restore_to_time + 1.hour,
          last_incremental_merge_requests_updated_at: restore_to_time - 1.day,
          last_incremental_issues_id: 100,
          last_incremental_merge_requests_id: 100
        )

        migrate!

        expect(rec1.reload.last_incremental_issues_id).to eq(100)
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { schema_migrate_down! }.not_to raise_error
    end
  end
end
