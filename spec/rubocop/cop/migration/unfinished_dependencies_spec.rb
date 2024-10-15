# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/unfinished_dependencies'

RSpec.describe RuboCop::Cop::Migration::UnfinishedDependencies, feature_category: :database do
  let(:version) { 20230307160250 }

  let(:migration) do
    <<~RUBY
      class TestMigration < Gitlab::Database::Migration[2.1]
        def perform; end
      end
    RUBY
  end

  before do
    allow(cop).to receive(:in_migration?).and_return(true)

    allow(cop).to receive(:version).and_return(version)
  end

  shared_examples 'migration with rubocop offense' do
    it 'registers an offense' do
      expect_offense(migration)
    end
  end

  shared_examples 'migration without any rubocop offense' do
    it 'does not register any offense' do
      expect_no_offenses(migration)
    end
  end

  context 'without any dependent batched background migrations' do
    it_behaves_like 'migration without any rubocop offense'
  end

  context 'with dependent batched background migrations' do
    let(:dependent_migration_versions) { [20230307160240] }

    let(:migration) do
      <<~RUBY
        class TestMigration < Gitlab::Database::Migration[2.1]
          DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = #{dependent_migration_versions}

          def perform; end
        end
      RUBY
    end

    context 'with unfinished dependent migration' do
      before do
        allow(cop).to receive(:fetch_finalized_by)
          .with(dependent_migration_versions.first)
          .and_return(nil)
      end

      it_behaves_like 'migration with rubocop offense' do
        let(:migration) do
          <<~RUBY
            class TestMigration < Gitlab::Database::Migration[2.1]
              DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = #{dependent_migration_versions}
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(described_class::NOT_FINALIZED_MSG, version: dependent_migration_versions.first)}

              def perform; end
            end
          RUBY
        end
      end
    end

    context 'with incorrectly finalized dependent migration' do
      let(:dependent_migration_versions) { [20230307160240, 20230307160230] }

      before do
        allow(cop).to receive(:fetch_finalized_by)
          .with(dependent_migration_versions.first)
          .and_return(version - 10)

        allow(cop).to receive(:fetch_finalized_by)
          .with(dependent_migration_versions.last)
          .and_return(version + 10)
      end

      it_behaves_like 'migration with rubocop offense' do
        let(:migration) do
          <<~RUBY
            class TestMigration < Gitlab::Database::Migration[2.1]
              DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = #{dependent_migration_versions}
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(described_class::FINALIZED_BY_LATER_MIGRATION_MSG, version: dependent_migration_versions.last)}

              def perform; end
            end
          RUBY
        end
      end
    end

    context 'with properly finalized dependent background migrations' do
      before do
        allow_next_instance_of(Gitlab::Utils::BatchedBackgroundMigrationsDictionary) do |bbms|
          allow(bbms).to receive(:finalized_by).and_return(version - 5)
        end
      end

      it_behaves_like 'migration without any rubocop offense'
    end
  end

  context 'for non migrations' do
    before do
      allow(cop).to receive(:in_migration?).and_return(false)
    end

    it_behaves_like 'migration without any rubocop offense'
  end
end
