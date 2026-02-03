# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/active_context_migration_reference_exists'

RSpec.describe RuboCop::Cop::Migration::ActiveContextMigrationReferenceExists, feature_category: :global_search do
  let(:migrations_path) { 'ee/active_context/migrate' }

  before do
    # Mock Rails.root to return current directory
    allow(Rails).to receive(:root).and_return(Pathname.new(Dir.pwd)) if defined?(Rails)
  end

  context 'when migration file exists' do
    before do
      # Stub Dir.glob to simulate existing migration files
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob)
        .with(%r{ee/active_context/migrate/\*_create_code\.rb})
        .and_return(['ee/active_context/migrate/20251029093945_create_code.rb'])
      allow(Dir).to receive(:glob)
        .with(%r{ee/active_context/migrate/\*_update_code_metadata\.rb})
        .and_return(['ee/active_context/migrate/20251029094016_update_code_metadata.rb'])
    end

    it 'does not register an offense for existing migration class name' do
      expect_no_offenses(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('CreateCode')
      RUBY
    end

    it 'does not register an offense for existing migration class name with :: prefix' do
      expect_no_offenses(<<~RUBY)
        ::Ai::ActiveContext::Migration.complete?('CreateCode')
      RUBY
    end

    it 'does not register an offense for another existing migration' do
      expect_no_offenses(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('UpdateCodeMetadata')
      RUBY
    end
  end

  context 'when using version timestamp' do
    it 'does not register an offense for valid 14-digit version' do
      expect_no_offenses(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('20251029093945')
      RUBY
    end

    it 'does not register an offense for another valid version' do
      expect_no_offenses(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('20251029094016')
      RUBY
    end

    it 'does not register an offense for version with :: prefix' do
      expect_no_offenses(<<~RUBY)
        ::Ai::ActiveContext::Migration.complete?('12345678901234')
      RUBY
    end
  end

  context 'when migration file does not exist' do
    before do
      # Stub Dir.glob to simulate no matching migration files
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob)
        .with(%r{ee/active_context/migrate/\*_set_code_indexing_versions\.rb})
        .and_return([])
      allow(Dir).to receive(:glob)
        .with(%r{ee/active_context/migrate/\*_non_existent_migration\.rb})
        .and_return([])
      allow(Dir).to receive(:glob)
        .with(%r{ee/active_context/migrate/\*_drop_code\.rb})
        .and_return([])
    end

    it 'registers an offense for non-existent migration class name' do
      expect_offense(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('SetCodeIndexingVersions')
                                               ^^^^^^^^^^^^^^^^^^^^^^^^^ ActiveContext migration `SetCodeIndexingVersions` does not exist. Ensure the migration file exists in ee/active_context/migrate/ or use a valid version timestamp.
      RUBY
    end

    it 'registers an offense for another non-existent migration' do
      expect_offense(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('NonExistentMigration')
                                               ^^^^^^^^^^^^^^^^^^^^^^ ActiveContext migration `NonExistentMigration` does not exist. Ensure the migration file exists in ee/active_context/migrate/ or use a valid version timestamp.
      RUBY
    end

    it 'registers an offense for removed migration (real-world bug case)' do
      expect_offense(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('DropCode')
                                               ^^^^^^^^^^ ActiveContext migration `DropCode` does not exist. Ensure the migration file exists in ee/active_context/migrate/ or use a valid version timestamp.
      RUBY
    end

    it 'registers an offense with :: prefix' do
      expect_offense(<<~RUBY)
        ::Ai::ActiveContext::Migration.complete?('SetCodeIndexingVersions')
                                                 ^^^^^^^^^^^^^^^^^^^^^^^^^ ActiveContext migration `SetCodeIndexingVersions` does not exist. Ensure the migration file exists in ee/active_context/migrate/ or use a valid version timestamp.
      RUBY
    end
  end

  context 'when using non-literal strings' do
    it 'does not register an offense for variable' do
      expect_no_offenses(<<~RUBY)
        migration_name = 'SomeMigration'
        Ai::ActiveContext::Migration.complete?(migration_name)
      RUBY
    end

    it 'does not register an offense for interpolated string' do
      expect_no_offenses(<<~RUBY)
        name = 'Migration'
        Ai::ActiveContext::Migration.complete?("\#{name}")
      RUBY
    end

    it 'does not register an offense for method call result' do
      expect_no_offenses(<<~RUBY)
        Ai::ActiveContext::Migration.complete?(get_migration_name)
      RUBY
    end
  end

  context 'when called on different classes' do
    it 'does not register an offense for different class' do
      expect_no_offenses(<<~RUBY)
        SomeOtherClass.complete?('NonExistentMigration')
      RUBY
    end

    it 'does not register an offense for partial match' do
      expect_no_offenses(<<~RUBY)
        ActiveContext::Migration.complete?('NonExistentMigration')
      RUBY
    end
  end

  context 'with edge cases' do
    it 'does not register an offense for empty string' do
      expect_no_offenses(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('')
      RUBY
    end

    it 'fails safe on Dir.glob errors by reporting offense' do
      allow(Dir).to receive(:glob).and_raise(StandardError, 'Test error')

      # Should not crash, but should report offense (fail safe)
      expect_offense(<<~RUBY)
        Ai::ActiveContext::Migration.complete?('SomeMigration')
                                               ^^^^^^^^^^^^^^^ ActiveContext migration `SomeMigration` does not exist. Ensure the migration file exists in ee/active_context/migrate/ or use a valid version timestamp.
      RUBY
    end
  end

  context 'with real-world code examples' do
    before do
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob)
        .with(%r{ee/active_context/migrate/\*_create_code\.rb})
        .and_return(['ee/active_context/migrate/20251029093945_create_code.rb'])
      allow(Dir).to receive(:glob)
        .with(%r{ee/active_context/migrate/\*_set_code_indexing_versions\.rb})
        .and_return([])
    end

    it 'does not register an offense for the fixed code' do
      expect_no_offenses(<<~RUBY)
        def self.indexing?
          ::ActiveContext.indexing? && current_indexing_embedding_versions.present?
        end
      RUBY
    end

    it 'would have caught the bug in MR !220715' do
      expect_offense(<<~RUBY)
        def self.indexing?
          ::ActiveContext.indexing? && Ai::ActiveContext::Migration.complete?('SetCodeIndexingVersions')
                                                                              ^^^^^^^^^^^^^^^^^^^^^^^^^ ActiveContext migration `SetCodeIndexingVersions` does not exist. Ensure the migration file exists in ee/active_context/migrate/ or use a valid version timestamp.
        end
      RUBY
    end

    it 'allows valid migration reference' do
      expect_no_offenses(<<~RUBY)
        def self.indexing?
          ::ActiveContext.indexing? && Ai::ActiveContext::Migration.complete?('CreateCode')
        end
      RUBY
    end
  end
end
