# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleUpdateExistingSubgroupToMatchVisibilityLevelOfParent do
  include MigrationHelpers::NamespacesHelpers
  let(:migration_class) { described_class::MIGRATION }
  let(:migration_name)  { migration_class.to_s.demodulize }

  context 'private visibility level' do
    it 'correctly schedules background migrations' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: parent.id)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(1)
          expect(migration_name).to be_scheduled_migration_with_multiple_args([parent.id], Gitlab::VisibilityLevel::PRIVATE)
        end
      end
    end

    it 'correctly schedules background migrations for groups and subgroups' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      middle_group = create_namespace('middle_group', Gitlab::VisibilityLevel::PRIVATE, parent_id: parent.id)
      create_namespace('middle_empty_group', Gitlab::VisibilityLevel::PRIVATE, parent_id: parent.id)
      create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group.id)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(1)
          expect(migration_name).to be_scheduled_migration_with_multiple_args([middle_group.id, parent.id], Gitlab::VisibilityLevel::PRIVATE)
        end
      end
    end
  end

  context 'internal visibility level' do
    it 'correctly schedules background migrations' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::INTERNAL)
      middle_group = create_namespace('child', Gitlab::VisibilityLevel::INTERNAL, parent_id: parent.id)
      create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group.id)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(1)
          expect(migration_name).to be_scheduled_migration_with_multiple_args([parent.id, middle_group.id], Gitlab::VisibilityLevel::INTERNAL)
        end
      end
    end
  end

  context 'mixed visibility levels' do
    it 'correctly schedules background migrations' do
      parent1 = create_namespace('parent1', Gitlab::VisibilityLevel::INTERNAL)
      create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: parent1.id)
      parent2 = create_namespace('parent2', Gitlab::VisibilityLevel::PRIVATE)
      middle_group = create_namespace('middle_group', Gitlab::VisibilityLevel::INTERNAL, parent_id: parent2.id)
      create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group.id)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
          expect(migration_name).to be_scheduled_migration_with_multiple_args([parent1.id, middle_group.id], Gitlab::VisibilityLevel::INTERNAL)
          expect(migration_name).to be_scheduled_migration_with_multiple_args([parent2.id], Gitlab::VisibilityLevel::PRIVATE)
        end
      end
    end
  end
end
