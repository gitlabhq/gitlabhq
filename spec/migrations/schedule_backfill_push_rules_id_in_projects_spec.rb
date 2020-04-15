# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db', 'post_migrate', '20200325162730_schedule_backfill_push_rules_id_in_projects.rb')

describe ScheduleBackfillPushRulesIdInProjects do
  let(:push_rules) { table(:push_rules) }

  it 'adds global rule association to application settings' do
    application_settings = table(:application_settings)
    setting = application_settings.create!
    sample_rule = push_rules.create!(is_sample: true)

    Sidekiq::Testing.fake! do
      disable_migrations_output { migrate! }
    end

    setting.reload
    expect(setting.push_rule_id).to eq(sample_rule.id)
  end

  it 'schedules worker to migrate project push rules' do
    rule_1 = push_rules.create!
    rule_2 = push_rules.create!

    Sidekiq::Testing.fake! do
      disable_migrations_output { migrate! }

      expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      expect(described_class::MIGRATION)
        .to be_scheduled_delayed_migration(5.minutes, rule_1.id, rule_2.id)
    end
  end
end
