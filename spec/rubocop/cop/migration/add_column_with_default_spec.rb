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
          add_column_with_default(:merge_request_diff_files, :artifacts, :boolean, default: true, allow_null: false)
        end
      RUBY
    end
  end

  context 'in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    let(:offense) { '`add_column_with_default` is deprecated, use `add_column` instead' }

    it 'registers an offense ' do
      expect_offense(<<~RUBY)
        def up
          add_column_with_default(:merge_request_diff_files, :artifacts, :boolean, default: true, allow_null: false)
          ^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
        end
      RUBY
    end
  end
end
