require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190527194900_schedule_calculate_wiki_sizes.rb')

describe ScheduleCalculateWikiSizes, :migration, :sidekiq do
  let(:migration_class) { Gitlab::BackgroundMigration::CalculateWikiSizes }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_statistics) { table(:project_statistics) }

  context 'when missing wiki sizes exist' do
    before do
      namespaces.create!(id: 1, name: 'wiki-migration', path: 'wiki-migration')
      projects.create!(id: 1, name: 'wiki-project-1', path: 'wiki-project-1', namespace_id: 1)
      projects.create!(id: 2, name: 'wiki-project-2', path: 'wiki-project-2', namespace_id: 1)
      projects.create!(id: 3, name: 'wiki-project-3', path: 'wiki-project-3', namespace_id: 1)
      project_statistics.create!(id: 1, project_id: 1, namespace_id: 1, wiki_size: 1000)
      project_statistics.create!(id: 2, project_id: 2, namespace_id: 1, wiki_size: nil)
      project_statistics.create!(id: 3, project_id: 3, namespace_id: 1, wiki_size: nil)
    end

    it 'schedules a background migration' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!

          expect(migration_name).to be_scheduled_delayed_migration(5.minutes, 2, 3)
          expect(BackgroundMigrationWorker.jobs.size).to eq 1
        end
      end
    end

    it 'calculates missing wiki sizes' do
      expect(project_statistics.find_by(id: 2).wiki_size).to be_nil
      expect(project_statistics.find_by(id: 3).wiki_size).to be_nil

      migrate!

      expect(project_statistics.find_by(id: 2).wiki_size).not_to be_nil
      expect(project_statistics.find_by(id: 3).wiki_size).not_to be_nil
    end
  end

  context 'when missing wiki sizes do not exist' do
    before do
      namespaces.create!(id: 1, name: 'wiki-migration', path: 'wiki-migration')
      projects.create!(id: 1, name: 'wiki-project-1', path: 'wiki-project-1', namespace_id: 1)
      project_statistics.create!(id: 1, project_id: 1, namespace_id: 1, wiki_size: 1000)
    end

    it 'does not schedule a background migration' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq 0
        end
      end
    end
  end
end
