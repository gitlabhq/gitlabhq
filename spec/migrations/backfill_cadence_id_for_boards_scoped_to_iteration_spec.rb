# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillCadenceIdForBoardsScopedToIteration, :migration, feature_category: :team_planning do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:iterations_cadences) { table(:iterations_cadences) }
  let(:boards) { table(:boards) }

  let!(:group) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
  let!(:cadence) { iterations_cadences.create!(title: 'group cadence', group_id: group.id, start_date: Time.current) }
  let!(:project) { projects.create!(name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }
  let!(:project_board1) { boards.create!(name: 'Project Dev1', project_id: project.id) }
  let!(:project_board2) { boards.create!(name: 'Project Dev2', project_id: project.id, iteration_id: -4) }
  let!(:project_board3) { boards.create!(name: 'Project Dev3', project_id: project.id, iteration_id: -4) }
  let!(:project_board4) { boards.create!(name: 'Project Dev4', project_id: project.id, iteration_id: -4) }

  let!(:group_board1) { boards.create!(name: 'Group Dev1', group_id: group.id) }
  let!(:group_board2) { boards.create!(name: 'Group Dev2', group_id: group.id, iteration_id: -4) }
  let!(:group_board3) { boards.create!(name: 'Group Dev3', group_id: group.id, iteration_id: -4) }
  let!(:group_board4) { boards.create!(name: 'Group Dev4', group_id: group.id, iteration_id: -4) }

  describe '#up' do
    it 'schedules background migrations' do
      Sidekiq::Testing.fake! do
        freeze_time do
          described_class.new.up

          migration = described_class::MIGRATION

          expect(migration).to be_scheduled_delayed_migration(2.minutes, 'group', 'up', group_board2.id, group_board4.id)
          expect(migration).to be_scheduled_delayed_migration(2.minutes, 'project', 'up', project_board2.id, project_board4.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq 2
        end
      end
    end

    context 'in batches' do
      before do
        stub_const('BackfillCadenceIdForBoardsScopedToIteration::BATCH_SIZE', 2)
      end

      it 'schedules background migrations' do
        Sidekiq::Testing.fake! do
          freeze_time do
            described_class.new.up

            migration = described_class::MIGRATION

            expect(migration).to be_scheduled_delayed_migration(2.minutes, 'group', 'up', group_board2.id, group_board3.id)
            expect(migration).to be_scheduled_delayed_migration(4.minutes, 'group', 'up', group_board4.id, group_board4.id)
            expect(migration).to be_scheduled_delayed_migration(2.minutes, 'project', 'up', project_board2.id, project_board3.id)
            expect(migration).to be_scheduled_delayed_migration(4.minutes, 'project', 'up', project_board4.id, project_board4.id)
            expect(BackgroundMigrationWorker.jobs.size).to eq 4
          end
        end
      end
    end
  end

  describe '#down' do
    let!(:project_board1) { boards.create!(name: 'Project Dev1', project_id: project.id) }
    let!(:project_board2) { boards.create!(name: 'Project Dev2', project_id: project.id, iteration_cadence_id: cadence.id) }
    let!(:project_board3) { boards.create!(name: 'Project Dev3', project_id: project.id, iteration_id: -4, iteration_cadence_id: cadence.id) }
    let!(:project_board4) { boards.create!(name: 'Project Dev4', project_id: project.id, iteration_id: -4, iteration_cadence_id: cadence.id) }

    let!(:group_board1) { boards.create!(name: 'Group Dev1', group_id: group.id) }
    let!(:group_board2) { boards.create!(name: 'Group Dev2', group_id: group.id, iteration_cadence_id: cadence.id) }
    let!(:group_board3) { boards.create!(name: 'Group Dev3', group_id: group.id, iteration_id: -4, iteration_cadence_id: cadence.id) }
    let!(:group_board4) { boards.create!(name: 'Group Dev4', group_id: group.id, iteration_id: -4, iteration_cadence_id: cadence.id) }

    it 'schedules background migrations' do
      Sidekiq::Testing.fake! do
        freeze_time do
          described_class.new.down

          migration = described_class::MIGRATION

          expect(migration).to be_scheduled_delayed_migration(2.minutes, 'none', 'down', project_board2.id, group_board4.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq 1
        end
      end
    end

    context 'in batches' do
      before do
        stub_const('BackfillCadenceIdForBoardsScopedToIteration::BATCH_SIZE', 2)
      end

      it 'schedules background migrations' do
        Sidekiq::Testing.fake! do
          freeze_time do
            described_class.new.down

            migration = described_class::MIGRATION

            expect(migration).to be_scheduled_delayed_migration(2.minutes, 'none', 'down', project_board2.id, project_board3.id)
            expect(migration).to be_scheduled_delayed_migration(4.minutes, 'none', 'down', project_board4.id, group_board2.id)
            expect(migration).to be_scheduled_delayed_migration(6.minutes, 'none', 'down', group_board3.id, group_board4.id)
            expect(BackgroundMigrationWorker.jobs.size).to eq 3
          end
        end
      end
    end
  end
end
