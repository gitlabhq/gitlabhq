# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/versioned_migration_class'

RSpec.describe RuboCop::Cop::Migration::VersionedMigrationClass, feature_category: :database do
  let(:migration) do
    <<~SOURCE
      class TestMigration < Gitlab::Database::Migration[2.1]
        def up
          execute 'select 1'
        end

        def down
          execute 'select 1'
        end
      end
    SOURCE
  end

  shared_examples 'a disabled cop' do
    it 'does not register any offenses' do
      expect_no_offenses(migration)
    end
  end

  context 'outside of a migration' do
    it_behaves_like 'a disabled cop'
  end

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'in an old migration' do
      before do
        allow(cop).to receive(:version).and_return(described_class::ENFORCED_SINCE - 5)
      end

      it_behaves_like 'a disabled cop'
    end

    context 'that is recent' do
      before do
        allow(cop).to receive(:version).and_return(described_class::ENFORCED_SINCE + 5)
      end

      it 'adds an offence if inheriting from ActiveRecord::Migration' do
        expect_offense(<<~RUBY)
          class MyMigration < ActiveRecord::Migration[6.1]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't inherit from ActiveRecord::Migration or old versions of Gitlab::Database::Migration. Use Gitlab::Database::Migration[#{described_class::CURRENT_MIGRATION_VERSION}] instead. See https://docs.gitlab.com/ee/development/migration_style_guide.html#migration-helpers-and-versioning.
          end
        RUBY
      end

      it 'adds an offence if inheriting from old version of Gitlab::Database::Migration' do
        expect_offense(<<~RUBY)
          class MyMigration < Gitlab::Database::Migration[2.0]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't inherit from ActiveRecord::Migration or old versions of Gitlab::Database::Migration. Use Gitlab::Database::Migration[#{described_class::CURRENT_MIGRATION_VERSION}] instead. See https://docs.gitlab.com/ee/development/migration_style_guide.html#migration-helpers-and-versioning.
          end
        RUBY
      end

      it 'adds an offence if including Gitlab::Database::MigrationHelpers directly' do
        expect_offense(<<~RUBY)
          class MyMigration < Gitlab::Database::Migration[#{described_class::CURRENT_MIGRATION_VERSION}]
            include Gitlab::Database::MigrationHelpers
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't include migration helper modules directly. Inherit from Gitlab::Database::Migration[#{described_class::CURRENT_MIGRATION_VERSION}] instead. See https://docs.gitlab.com/ee/development/migration_style_guide.html#migration-helpers-and-versioning.
          end
        RUBY
      end

      it 'excludes ActiveRecord classes defined inside the migration' do
        expect_no_offenses(<<~RUBY)
          class TestMigration < Gitlab::Database::Migration[#{described_class::CURRENT_MIGRATION_VERSION}]
            class TestModel < ApplicationRecord
            end

            class AnotherTestModel < ActiveRecord::Base
            end
          end
        RUBY
      end

      it 'excludes parentless classes defined inside the migration' do
        expect_no_offenses(<<~RUBY)
          class TestMigration < Gitlab::Database::Migration[#{described_class::CURRENT_MIGRATION_VERSION}]
            class TestClass
            end
          end
        RUBY
      end
    end
  end
end
