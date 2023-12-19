# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:decomposition:migrate', feature_category: :cell do
  before(:all) do
    skip_if_database_exists(:ci)

    Rake.application.rake_require 'tasks/gitlab/db/decomposition/migrate'
  end

  subject(:migrate_task) { run_rake_task('gitlab:db:decomposition:migrate') }

  before do
    allow_next_instance_of(Gitlab::Database::Decomposition::Migrate) do |instance|
      allow(instance).to receive(:process!)
    end
  end

  it 'calls Gitlab::Database::Decomposition::Migrate#process!' do
    expect_next_instance_of(Gitlab::Database::Decomposition::Migrate) do |instance|
      expect(instance).to receive(:process!)
    end

    migrate_task
  end

  context 'when a Gitlab::Database::Decomposition::Migrate::Error is raised' do
    before do
      allow_next_instance_of(Gitlab::Database::Decomposition::Migrate) do |instance|
        allow(instance).to receive(:process!).and_raise(Gitlab::Database::Decomposition::MigrateError, 'some error')
      end
    end

    it 'renders error' do
      expect { migrate_task }.to output("some error\n").to_stdout.and raise_error(SystemExit)
    end
  end
end
