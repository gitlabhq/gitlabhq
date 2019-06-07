require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181121111200_schedule_runners_token_encryption')

describe ScheduleRunnersTokenEncryption, :migration, :sidekiq do
  let(:settings) { table(:application_settings) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:runners) { table(:ci_runners) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    settings.create!(id: 1, runners_registration_token: 'plain-text-token1')
    namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab-org', runners_token: 'my-token1')
    namespaces.create!(id: 12, name: 'gitlab', path: 'gitlab-org', runners_token: 'my-token2')
    projects.create!(id: 111, namespace_id: 11, name: 'gitlab', path: 'gitlab-ce', runners_token: 'my-token1')
    projects.create!(id: 114, namespace_id: 11, name: 'gitlab', path: 'gitlab-ce', runners_token: 'my-token2')
    runners.create!(id: 201, runner_type: 1, token: 'plain-text-token1')
    runners.create!(id: 202, runner_type: 1, token: 'plain-text-token2')
  end

  it 'schedules runners token encryption migration for multiple resources' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 'settings', 1, 1)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 'namespace', 11, 11)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(8.minutes, 'namespace', 12, 12)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 'project', 111, 111)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(8.minutes, 'project', 114, 114)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 'runner', 201, 201)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(8.minutes, 'runner', 202, 202)
        expect(BackgroundMigrationWorker.jobs.size).to eq 7
      end
    end
  end
end
