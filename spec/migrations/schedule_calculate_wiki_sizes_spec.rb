# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190527194900_schedule_calculate_wiki_sizes.rb')

RSpec.describe ScheduleCalculateWikiSizes do
  let(:migration_class) { Gitlab::BackgroundMigration::CalculateWikiSizes }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_statistics) { table(:project_statistics) }
  let(:namespace) { namespaces.create!(name: 'wiki-migration', path: 'wiki-migration') }
  let(:project1) { projects.create!(name: 'wiki-project-1', path: 'wiki-project-1', namespace_id: namespace.id) }
  let(:project2) { projects.create!(name: 'wiki-project-2', path: 'wiki-project-2', namespace_id: namespace.id) }
  let(:project3) { projects.create!(name: 'wiki-project-3', path: 'wiki-project-3', namespace_id: namespace.id) }

  context 'when missing wiki sizes exist' do
    let!(:project_statistic1) { project_statistics.create!(project_id: project1.id, namespace_id: namespace.id, wiki_size: 1000) }
    let!(:project_statistic2) { project_statistics.create!(project_id: project2.id, namespace_id: namespace.id, wiki_size: nil) }
    let!(:project_statistic3) { project_statistics.create!(project_id: project3.id, namespace_id: namespace.id, wiki_size: nil) }

    it 'schedules a background migration' do
      freeze_time do
        migrate!

        expect(migration_name).to be_scheduled_delayed_migration(5.minutes, project_statistic2.id, project_statistic3.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq 1
      end
    end

    it 'calculates missing wiki sizes', :sidekiq_inline do
      expect(project_statistic2.wiki_size).to be_nil
      expect(project_statistic3.wiki_size).to be_nil

      migrate!

      expect(project_statistic2.reload.wiki_size).not_to be_nil
      expect(project_statistic3.reload.wiki_size).not_to be_nil
    end
  end

  context 'when missing wiki sizes do not exist' do
    before do
      namespace = namespaces.create!(name: 'wiki-migration', path: 'wiki-migration')
      project = projects.create!(name: 'wiki-project-1', path: 'wiki-project-1', namespace_id: namespace.id)
      project_statistics.create!(project_id: project.id, namespace_id: namespace.id, wiki_size: 1000)
    end

    it 'does not schedule a background migration' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq 0
        end
      end
    end
  end
end
