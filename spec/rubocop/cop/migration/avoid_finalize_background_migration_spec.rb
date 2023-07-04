# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/avoid_finalize_background_migration'

RSpec.describe RuboCop::Cop::Migration::AvoidFinalizeBackgroundMigration, feature_category: :database do
  context 'when file is under db/post_migration' do
    it "flags the use of 'finalize_background_migration' method" do
      expect_offense(<<~RUBY)
        class FinalizeMyMigration < Gitlab::Database::Migration[2.1]
           MIGRATION = 'MyMigration'

           def up
             finalize_background_migration(MIGRATION)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
           end
        end
      RUBY
    end
  end
end
