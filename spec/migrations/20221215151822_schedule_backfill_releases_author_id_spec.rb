# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleBackfillReleasesAuthorId, feature_category: :release_orchestration do
  context 'when there are releases without author' do
    let(:releases_table) { table(:releases) }
    let(:user_table) { table(:users) }
    let(:date_time) { DateTime.now }
    let!(:batched_migration) { described_class::MIGRATION }
    let!(:test_user) do
      user_table.create!(
        name: 'test',
        email: 'test@example.com',
        username: 'test',
        projects_limit: 10
      )
    end

    before do
      releases_table.create!(
        tag: 'tag1', name: 'tag1', released_at: (date_time - 1.minute), author_id: test_user.id
      )
      releases_table.create!(
        tag: 'tag2', name: 'tag2', released_at: (date_time - 2.minutes), author_id: test_user.id
      )
      releases_table.new(
        tag: 'tag3', name: 'tag3', released_at: (date_time - 3.minutes), author_id: nil
      ).save!(validate: false)
      releases_table.new(
        tag: 'tag4', name: 'tag4', released_at: (date_time - 4.minutes), author_id: nil
      ).save!(validate: false)
    end

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :releases,
            column_name: :id,
            interval: described_class::JOB_DELAY_INTERVAL,
            job_arguments: [User.find_by(user_type: :ghost)&.id]
          )
        }
      end
    end
  end

  context 'when there are no releases without author' do
    it 'does not schedule batched migration' do
      expect(described_class.new.up).not_to have_scheduled_batched_migration
    end
  end
end
