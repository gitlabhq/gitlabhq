# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/migration_record'

RSpec.describe RuboCop::Cop::Migration::MigrationRecord do
  subject(:cop) { described_class.new }

  let(:migration) do
    <<~SOURCE
      class MyMigration < Gitlab::Database::Migration[2.0]
        class Project < ActiveRecord::Base
        end

        def change
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
        allow(cop).to receive(:version).and_return(described_class::ENFORCED_SINCE)
      end

      it 'adds an offense if inheriting from ActiveRecord::Base' do
        expect_offense(<<~RUBY)
          class Project < ActiveRecord::Base
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't inherit from ActiveRecord::Base but use MigrationRecord instead.[...]
          end
        RUBY
      end

      context 'when migration inhertis from ::ActiveRecord::Base' do
        let(:migration) do
          <<~SOURCE
            class MyMigration < Gitlab::Database::Migration[2.0]
              class Project < ::ActiveRecord::Base
              end
      
              def change
              end
            end
          SOURCE
        end

        it 'adds an offense' do
          expect_offense(<<~RUBY)
            class Project < ::ActiveRecord::Base
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't inherit from ActiveRecord::Base but use MigrationRecord instead.[...]
            end
          RUBY
        end
      end
    end
  end
end
