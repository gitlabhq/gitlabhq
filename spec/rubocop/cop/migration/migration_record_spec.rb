# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/migration_record'

RSpec.describe RuboCop::Cop::Migration::MigrationRecord do
  shared_examples 'a disabled cop' do |klass|
    it 'does not register any offenses' do
      expect_no_offenses(<<~SOURCE)
        class MyMigration < Gitlab::Database::Migration[2.0]
          class Project < #{klass}
          end
        end
      SOURCE
    end
  end

  %w[ActiveRecord::Base ApplicationRecord].each do |klass|
    context 'outside of a migration' do
      it_behaves_like 'a disabled cop', klass
    end

    context 'in migration' do
      before do
        allow(cop).to receive(:in_migration?).and_return(true)
      end

      context 'in an old migration' do
        before do
          allow(cop).to receive(:version).and_return(described_class::ENFORCED_SINCE - 5)
        end

        it_behaves_like 'a disabled cop', klass
      end

      context 'that is recent' do
        before do
          allow(cop).to receive(:version).and_return(described_class::ENFORCED_SINCE)
        end

        it "adds an offense if inheriting from #{klass}" do
          expect_offense(<<~RUBY)
          class Project < #{klass}
          ^^^^^^^^^^^^^^^^#{'^' * klass.length} Don't inherit from ActiveRecord::Base or ApplicationRecord but use MigrationRecord instead.[...]
          end
          RUBY
        end

        it "adds an offense if inheriting from ::#{klass}" do
          expect_offense(<<~RUBY)
          class Project < ::#{klass}
          ^^^^^^^^^^^^^^^^^^#{'^' * klass.length} Don't inherit from ActiveRecord::Base or ApplicationRecord but use MigrationRecord instead.[...]
          end
          RUBY
        end
      end
    end
  end
end
