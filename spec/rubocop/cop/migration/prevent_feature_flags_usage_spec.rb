# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_feature_flags_usage'

RSpec.describe RuboCop::Cop::Migration::PreventFeatureFlagsUsage, feature_category: :database do
  include RuboCop::MigrationHelpers

  let(:offense) do
    "Do not use Feature.enabled? or Feature.disabled? in migrations. " \
      "Use the feature_flag_enabled?(feature_name) migration helper method."
  end

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when using Feature.enabled?' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def change
            if Feature.enabled?(:some_feature)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              do_something
            end
          end
        RUBY
      end

      it 'registers an offense with a variable' do
        expect_offense(<<~RUBY)
          def change
            feature_name = :some_feature
            if Feature.enabled?(feature_name)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              do_something
            end
          end
        RUBY
      end

      it 'registers an offense with a string argument' do
        expect_offense(<<~RUBY)
          def change
            if Feature.enabled?('some_feature')
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              do_something
            end
          end
        RUBY
      end
    end

    context 'when using Feature.disabled?' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def change
            if Feature.disabled?(:some_feature)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              do_something
            end
          end
        RUBY
      end

      it 'registers an offense with a variable' do
        expect_offense(<<~RUBY)
          def change
            feature_name = :some_feature
            if Feature.disabled?(feature_name)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              do_something
            end
          end
        RUBY
      end
    end

    context 'when using feature_flag_enabled? helper' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def change
            if feature_flag_enabled?(:some_feature)
              do_something
            end
          end
        RUBY
      end
    end

    context 'when using other methods on Feature' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def change
            Feature.something_else(:some_feature)
          end
        RUBY
      end
    end
  end

  context 'when outside of migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(false)
    end

    it 'does not register an offense for Feature.enabled?' do
      expect_no_offenses(<<~RUBY)
        def some_method
          if Feature.enabled?(:some_feature)
            do_something
          end
        end
      RUBY
    end

    it 'does not register an offense for Feature.disabled?' do
      expect_no_offenses(<<~RUBY)
        def some_method
          if Feature.disabled?(:some_feature)
            do_something
          end
        end
      RUBY
    end
  end
end
