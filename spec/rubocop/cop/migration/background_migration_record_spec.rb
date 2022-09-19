# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/background_migration_record'

RSpec.describe RuboCop::Cop::Migration::BackgroundMigrationRecord do
  context 'outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~SOURCE)
        class MigrateProjectRecords
          class Project < ActiveRecord::Base
          end
        end
      SOURCE
    end
  end

  context 'in migration' do
    before do
      allow(cop).to receive(:in_background_migration?).and_return(true)
    end

    it 'adds an offense if inheriting from ActiveRecord::Base' do
      expect_offense(<<~RUBY)
        class MigrateProjectRecords
          class Project < ActiveRecord::Base
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use or inherit from ActiveRecord::Base.[...]
          end
        end
      RUBY
    end

    it 'adds an offense if create dynamic model from ActiveRecord::Base' do
      expect_offense(<<~RUBY)
        class MigrateProjectRecords
          def define_model(table_name)
            Class.new(ActiveRecord::Base) do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use or inherit from ActiveRecord::Base.[...]
              self.table_name = table_name
              self.inheritance_column = :_type_disabled
            end
          end
        end
      RUBY
    end

    it 'adds an offense if inheriting from ::ActiveRecord::Base' do
      expect_offense(<<~RUBY)
        class MigrateProjectRecords
          class Project < ::ActiveRecord::Base
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use or inherit from ActiveRecord::Base.[...]
          end
        end
      RUBY
    end
  end
end
