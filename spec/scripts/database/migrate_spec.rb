# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/database/migrate'

RSpec.describe 'Migrate', feature_category: :database do
  let(:direction) { 'up' }
  let(:files) { ['20231010123456_create_migration.rb'] }

  subject(:migrator) { Migrate.new }

  describe "#database_migration_tasks" do
    context 'when multiple databases are configured' do
      let(:rails_help_output) do
        <<~HELP
          db:migrate:up:ci                  # Runs the "up" for the given migration VERSION for the ci database
          db:migrate:up:main                # Runs the "up" for the given migration VERSION for the main database
          db:migrate:up                     # Runs the "up" for the given migration VERSION
          db:migrate:status                 # Display status of migrations
        HELP
      end

      it 'returns tasks for all configured databases' do
        expect(
          migrator.database_migration_tasks('up', rails_help_output)
        ).to match_array(['db:migrate:up:ci', 'db:migrate:up:main'])
      end
    end

    context 'when only the default database is configured' do
      let(:rails_help_output) do
        <<~HELP
          db:migrate:up:main                # Runs the "up" for the given migration VERSION
          db:migrate:status                 # Display status of migrations
        HELP
      end

      it 'returns only the default migration task' do
        expect(migrator.database_migration_tasks('up', rails_help_output)).to match_array(['db:migrate:up:main'])
      end
    end
  end

  describe "#migrations_for_files" do
    it 'returns the correct command' do
      allow(migrator).to receive(:database_migration_tasks).and_return(['db:migrate:up:ci', 'db:migrate:up:main'])

      expect(migrator.migrations_for_files(files, direction)).to eq(
        [
          'bin/rails db:migrate:up:ci db:migrate:up:main VERSION=20231010123456'
        ]
      )
    end
  end
end
