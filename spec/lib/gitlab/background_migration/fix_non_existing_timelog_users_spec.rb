# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixNonExistingTimelogUsers, feature_category: :team_planning do
  let(:users_table) { table(:users) }
  let(:timelogs_table) { table(:timelogs) }
  let(:organizations_table) { table(:organizations) }
  let(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }

  let(:user) { users_table.create!(email: generate(:email), projects_limit: 0, organization_id: organization.id) }
  let(:deleted_user) do
    users_table.create!(email: generate(:email), projects_limit: 0, organization_id: organization.id)
  end

  let!(:timelog_invalid) do
    timelogs_table.create!(user_id: deleted_user.id, time_spent: 5)
  end

  let!(:timelog_valid) do
    timelogs_table.create!(user_id: user.id, time_spent: 5)
  end

  let(:start_id) { timelogs_table.minimum(:id) }
  let(:end_id) { timelogs_table.maximum(:id) }

  describe '#perform' do
    it 'migrates the invalid timelog' do
      expect(timelog_invalid.reload.user_id).to eq(deleted_user.id)

      deleted_user.delete

      described_class.new(
        start_id: start_id,
        end_id: end_id,
        batch_table: :timelogs,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform

      expect(timelog_invalid.reload.user_id).to eq(Users::Internal.ghost.id)
      expect(timelog_valid.reload.user_id).to eq(user.id)
    end

    context 'when ghost user already exists' do
      let!(:ghost) { users_table.create!(user_type: 5, projects_limit: 0, organization_id: organization.id) }

      it 'migrates the invalid timelog to the existing ghost user' do
        expect(timelog_invalid.reload.user_id).to eq(deleted_user.id)

        deleted_user.delete

        described_class.new(
          start_id: start_id,
          end_id: end_id,
          batch_table: :timelogs,
          batch_column: :id,
          sub_batch_size: 2,
          pause_ms: 0,
          connection: ApplicationRecord.connection
        ).perform

        expect(timelog_invalid.reload.user_id).to eq(ghost.id)
        expect(timelog_valid.reload.user_id).to eq(user.id)
      end
    end
  end
end
