# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMembersRequestAcceptedAt, schema: 20240920083708, feature_category: :groups_and_projects do
  let!(:namespace) { table(:namespaces).create!({ name: "test-1", path: "test-1", owner_id: 1 }) }
  let!(:member) { table(:members) }
  let!(:member_data) do
    {
      access_level: ::Gitlab::Access::MAINTAINER,
      member_namespace_id: namespace.id,
      notification_level: 3,
      source_type: "Namespace",
      source_id: 22,
      created_at: "2024-09-14 06:06:16.649264"
    }
  end

  let!(:member1) { member.create!(member_data) }
  let!(:member2) { member.create!(member_data) }
  let!(:member3) { member.create!(member_data.merge(requested_at: Time.current)) }
  let!(:member4) { member.create!(member_data.merge(invite_token: 'token')) }
  let!(:member5) { member.create!(member_data.merge(request_accepted_at: Time.current)) }
  let!(:member6) { member.create!(member_data.merge(invite_accepted_at: Time.current)) }

  subject(:migration) do
    described_class.new(
      start_id: member1.id,
      end_id: member6.id,
      batch_table: :members,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'when `requested_at`, `invite_token`, `invite_accepted_at` and `request_accepted_at` are set to nil' do
      it 'backfills `request_accepted_at` column to `created_at` for eligible members' do
        expect { migration.perform }
          .to change { member1.reload.request_accepted_at }.from(nil).to(member1.created_at)
          .and change { member2.reload.request_accepted_at }.from(nil).to(member2.created_at)
          .and not_change { member3.reload.request_accepted_at }
          .and not_change { member4.reload.request_accepted_at }
          .and not_change { member5.reload.request_accepted_at }
          .and not_change { member6.reload.request_accepted_at }
      end
    end
  end
end
