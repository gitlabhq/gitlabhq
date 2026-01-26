# frozen_string_literal: true

require 'spec_helper'
require './keeps/overdue_finalize_background_migration'

RSpec.describe Keeps::OverdueFinalizeBackgroundMigrations::OutdatedMigrationChecker, feature_category: :tooling do
  subject(:calculator) { described_class.new(logger: logger) }

  let(:logger) { instance_double(Logger, puts: nil) }

  describe '#existing_migration_timestamp_outdated?' do
    let(:identifiers) { %w[OverdueFinalizeBackgroundMigration TestMigration] }
    let(:git) { instance_double(Gitlab::Housekeeper::Git) }
    let(:branch_name) { 'overdue-finalize-background-migration-test-migration' }

    before do
      allow(Gitlab::Housekeeper::Git).to receive(:branch_name).with(identifiers).and_return(branch_name)
      allow(Gitlab::Housekeeper::Git).to receive(:new).with(logger: logger).and_return(git)
    end

    context 'when no migration timestamp is found' do
      before do
        allow(git).to receive(:remote_branch_changed_files)
                        .with(branch_name, 'db/schema_migrations/')
                        .and_return([])
      end

      it 'returns false' do
        expect(calculator.existing_migration_timestamp_outdated?(identifiers)).to be false
      end
    end

    context 'when remote branch fetch fails' do
      before do
        allow(git).to receive(:remote_branch_changed_files)
                        .with(branch_name, 'db/schema_migrations/')
                        .and_raise(Gitlab::Housekeeper::Shell::Error.new('fetch failed'))
      end

      it 'returns false' do
        expect(calculator.existing_migration_timestamp_outdated?(identifiers)).to be false
      end
    end

    context 'when migration timestamp is found' do
      let(:min_version) { Gitlab::VersionInfo.new(17, 4) }

      before do
        allow(Gitlab::Database).to receive(:min_schema_gitlab_version).and_return(min_version)
      end

      context 'when migration is older than age threshold' do
        before do
          old_timestamp = 5.weeks.ago.strftime('%Y%m%d%H%M%S')
          allow(git).to receive(:remote_branch_changed_files)
                          .with(branch_name, 'db/schema_migrations/')
                          .and_return(["db/schema_migrations/#{old_timestamp}"])
        end

        it 'returns true' do
          expect(calculator.existing_migration_timestamp_outdated?(identifiers)).to be true
        end
      end

      context 'when migration is recent' do
        before do
          recent_timestamp = 1.day.ago.strftime('%Y%m%d%H%M%S')
          allow(git).to receive(:remote_branch_changed_files)
                          .with(branch_name, 'db/schema_migrations/')
                          .and_return(["db/schema_migrations/#{recent_timestamp}"])
        end

        it 'returns false' do
          expect(calculator.existing_migration_timestamp_outdated?(identifiers)).to be false
        end
      end

      context 'when migration is before cutoff milestone timestamp' do
        before do
          old_milestone_timestamp = '20250101120000'
          allow(git).to receive(:remote_branch_changed_files)
                          .with(branch_name, 'db/schema_migrations/')
                          .and_return(["db/schema_migrations/#{old_milestone_timestamp}"])
        end

        it 'returns true' do
          expect(calculator.existing_migration_timestamp_outdated?(identifiers)).to be true
        end
      end

      context 'when changed files include non-migration files' do
        before do
          recent_timestamp = 1.day.ago.strftime('%Y%m%d%H%M%S')
          allow(git).to receive(:remote_branch_changed_files)
                          .with(branch_name, 'db/schema_migrations/')
                          .and_return(%W[db/schema_migrations/#{recent_timestamp} db/schema_migrations/README.md])
        end

        it 'only considers valid migration timestamps' do
          expect(calculator.existing_migration_timestamp_outdated?(identifiers)).to be false
        end
      end
    end
  end

  describe '#find_existing_remote_migration_timestamp' do
    let(:identifiers) { %w[OverdueFinalizeBackgroundMigration TestMigration] }
    let(:git) { instance_double(Gitlab::Housekeeper::Git) }
    let(:branch_name) { 'overdue-finalize-background-migration-test-migration' }

    before do
      allow(Gitlab::Housekeeper::Git).to receive(:branch_name).with(identifiers).and_return(branch_name)
      allow(Gitlab::Housekeeper::Git).to receive(:new).with(logger: logger).and_return(git)
    end

    context 'when schema_migrations file exists' do
      before do
        allow(git).to receive(:remote_branch_changed_files)
                        .with(branch_name, 'db/schema_migrations/')
                        .and_return(['db/schema_migrations/20250918232145'])
      end

      it 'returns the timestamp' do
        expect(calculator.send(:find_existing_remote_migration_timestamp, identifiers)).to eq('20250918232145')
      end
    end

    context 'when multiple files exist' do
      before do
        schema_migrations = %w[
          db/schema_migrations/README.md
          db/schema_migrations/20250918232145
          db/schema_migrations/.gitkeep
        ]
        allow(git).to receive(:remote_branch_changed_files)
                        .with(branch_name, 'db/schema_migrations/')
                        .and_return(schema_migrations)
      end

      it 'returns the first valid timestamp' do
        expect(calculator.send(:find_existing_remote_migration_timestamp, identifiers)).to eq('20250918232145')
      end
    end

    context 'when no valid schema_migrations file exists' do
      before do
        allow(git).to receive(:remote_branch_changed_files)
                        .with(branch_name, 'db/schema_migrations/')
                        .and_return(['db/schema_migrations/README.md'])
      end

      it 'returns nil' do
        expect(calculator.send(:find_existing_remote_migration_timestamp, identifiers)).to be_nil
      end
    end

    context 'when Shell::Error is raised' do
      before do
        allow(git).to receive(:remote_branch_changed_files)
                        .with(branch_name, 'db/schema_migrations/')
                        .and_raise(Gitlab::Housekeeper::Shell::Error.new('branch not found'))
      end

      it 'returns nil' do
        expect(calculator.send(:find_existing_remote_migration_timestamp, identifiers)).to be_nil
      end
    end
  end

  describe '#cutoff_milestone_timestamp' do
    using RSpec::Parameterized::TableSyntax

    where(:major, :minor, :expected_year, :expected_month) do
      18 | 8  | 2026 | 1 # January 2026 (base case)
      18 | 9  | 2026 | 2 # February 2026
      18 | 10 | 2026 | 3 # March 2026
    end

    with_them do
      it 'calculates the correct release month' do
        min_version = Gitlab::VersionInfo.new(major, minor)
        allow(Gitlab::Database).to receive(:min_schema_gitlab_version).and_return(min_version)

        # Create a new calculator instance to avoid memoization issues between examples
        calc = described_class.new(logger: logger)
        result = calc.send(:cutoff_milestone_timestamp)

        expect(result.year).to eq(expected_year)
        expect(result.month).to eq(expected_month)
      end

      it 'returns a time on the third Thursday' do
        min_version = Gitlab::VersionInfo.new(major, minor)
        allow(Gitlab::Database).to receive(:min_schema_gitlab_version).and_return(min_version)

        calc = described_class.new(logger: logger)
        result = calc.send(:cutoff_milestone_timestamp)

        # Third Thursday is always between 15th and 21st
        expect(result.day).to be_between(15, 21)
        expect(result.wday).to eq(4) # Thursday
      end
    end

    it 'memoizes the result' do
      min_version = Gitlab::VersionInfo.new(18, 8)
      allow(Gitlab::Database).to receive(:min_schema_gitlab_version).and_return(min_version)

      first_call = calculator.send(:cutoff_milestone_timestamp)
      second_call = calculator.send(:cutoff_milestone_timestamp)

      expect(first_call).to be(second_call)
    end
  end

  describe '#third_thursday_of_month' do
    using RSpec::Parameterized::TableSyntax

    where(:year, :month, :expected_day) do
      2026 | 1 | 15
      2026 | 2 | 19
      2026 | 3 | 19
    end

    with_them do
      it 'returns the third Thursday of the month' do
        result = calculator.send(:third_thursday_of_month, year, month)

        expect(result).to eq(Date.new(year, month, expected_day))
        expect(result.wday).to eq(4) # Thursday
      end
    end
  end
end
