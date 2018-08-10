require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/add_reference'

describe RuboCop::Cop::Migration::AddReference do
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

    it 'registers an offense when using add_reference without index' do
      expect_offense(<<~RUBY)
        call do
          add_reference(:projects, :users)
          ^^^^^^^^^^^^^ `add_reference` requires `index: true`
        end
      RUBY
    end

    it 'registers an offense when using add_reference index disabled' do
      expect_offense(<<~RUBY)
        def up
          add_reference(:projects, :users, index: false)
          ^^^^^^^^^^^^^ `add_reference` requires `index: true`
        end
      RUBY
    end

    it 'does not register an offense when using add_reference with index enabled' do
      expect_no_offenses(<<~RUBY)
        def up
          add_reference(:projects, :users, index: true)
        end
      RUBY
    end
  end
end
