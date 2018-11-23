require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181121111200_schedule_runners_token_encryption')

describe ScheduleRunnersTokenEncryption, :migration do
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

        expect(BackgroundMigrationWorker.jobs.size).to eq 7
      end
    end
  end
end
