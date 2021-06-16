# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixProjectsWithoutProjectFeature do
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab-org') }

  let!(:projects) do
    [
      table(:projects).create!(namespace_id: namespace.id, name: 'foo 1'),
      table(:projects).create!(namespace_id: namespace.id, name: 'foo 2'),
      table(:projects).create!(namespace_id: namespace.id, name: 'foo 3')
    ]
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  around do |example|
    Sidekiq::Testing.fake! do
      freeze_time do
        example.call
      end
    end
  end

  it 'schedules jobs for ranges of projects' do
    migrate!

    expect(described_class::MIGRATION)
      .to be_scheduled_delayed_migration(2.minutes, projects[0].id, projects[1].id)

    expect(described_class::MIGRATION)
      .to be_scheduled_delayed_migration(4.minutes, projects[2].id, projects[2].id)
  end

  it 'schedules jobs according to the configured batch size' do
    expect { migrate! }.to change { BackgroundMigrationWorker.jobs.size }.by(2)
  end
end
