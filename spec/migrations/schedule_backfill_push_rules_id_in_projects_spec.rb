# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ScheduleBackfillPushRulesIdInProjects do
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

  it 'adds global rule association to last application settings when there is more than one record without failing' do
    application_settings = table(:application_settings)
    setting_old = application_settings.create!
    setting = application_settings.create!
    sample_rule = push_rules.create!(is_sample: true)

    Sidekiq::Testing.fake! do
      disable_migrations_output { migrate! }
    end

    expect(setting_old.reload.push_rule_id).to be_nil
    expect(setting.reload.push_rule_id).to eq(sample_rule.id)
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
