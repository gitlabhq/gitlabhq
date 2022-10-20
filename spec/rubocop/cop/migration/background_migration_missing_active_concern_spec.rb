# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/background_migration_missing_active_concern'

RSpec.describe RuboCop::Cop::Migration::BackgroundMigrationMissingActiveConcern do
  shared_examples 'offense is not registered' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            prepended do
              scope_to -> (relation) { relation }
            end
          end
        end
      RUBY
    end
  end

  context 'when outside of a migration' do
    it_behaves_like 'offense is not registered'
  end

  context 'in non-ee background migration' do
    before do
      allow(cop).to receive(:in_ee_background_migration?).and_return(false)
    end

    it_behaves_like 'offense is not registered'
  end

  context 'in ee background migration' do
    before do
      allow(cop).to receive(:in_ee_background_migration?).and_return(true)
    end

    context 'when scope_to is not used inside prepended block' do
      it 'does not register any offenses' do
        expect_no_offenses(<<~RUBY)
          module Gitlab
            module BackgroundMigration
              prepended do
                some_method_to -> (relation) { relation }
              end

              def foo
                scope_to -> (relation) { relation }
              end
            end
          end
        RUBY
      end
    end

    context 'when scope_to is used inside prepended block' do
      it 'does not register any offenses if the module does extend ActiveSupport::Concern' do
        expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            extend ::Gitlab::Utils::Override
            extend ActiveSupport::Concern

            prepended do
              scope_to -> (relation) { relation }
            end
          end
        end
        RUBY
      end

      it 'registers an offense if the module does not extend ActiveSupport::Concern' do
        expect_offense(<<~RUBY)
          module Gitlab
            module BackgroundMigration
              prepended do
                scope_to -> (relation) { relation }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Extend `ActiveSupport::Concern` [...]
              end
            end
          end
        RUBY
      end
    end
  end
end
