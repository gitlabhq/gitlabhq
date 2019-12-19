# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/add_column_with_default'

describe RuboCop::Cop::Migration::AddColumnWithDefault do
  include CopHelper

  let(:cop) { described_class.new }

  context 'outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        def up
          add_reference(:projects, :users)
        end
      RUBY
    end
  end

  context 'in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    let(:offense) { '`add_column_with_default` with `allow_null: false` may cause prolonged lock situations and downtime, see https://gitlab.com/gitlab-org/gitlab/issues/38060' }

    it 'registers an offense when specifying allow_null: false' do
      expect_offense(<<~RUBY)
        def up
          add_column_with_default(:ci_build_needs, :artifacts, :boolean, default: true, allow_null: false)
          ^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
        end
      RUBY
    end

    it 'registers no offense when specifying allow_null: true' do
      expect_no_offenses(<<~RUBY)
        def up
          add_column_with_default(:ci_build_needs, :artifacts, :boolean, default: true, allow_null: true)
        end
      RUBY
    end

    it 'registers no offense when allow_null is not specified' do
      expect_no_offenses(<<~RUBY)
        def up
          add_column_with_default(:ci_build_needs, :artifacts, :boolean, default: true)
        end
      RUBY
    end

    it 'registers no offense for application_settings (whitelisted table)' do
      expect_no_offenses(<<~RUBY)
        def up
          add_column_with_default(:application_settings, :another_column, :boolean, default: true, allow_null: false)
        end
      RUBY
    end
  end
end
