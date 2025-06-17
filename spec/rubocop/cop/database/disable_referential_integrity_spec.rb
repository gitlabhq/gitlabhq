# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/disable_referential_integrity'

RSpec.describe RuboCop::Cop::Database::DisableReferentialIntegrity do
  it 'does not flag the use of disable_referential_integrity with a send receiver' do
    expect_offense(<<~RUBY)
      foo.disable_referential_integrity
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `disable_referential_integrity`, [...]
    RUBY
  end

  it 'flags the use of disable_referential_integrity with a full definition' do
    expect_offense(<<~RUBY)
      ActiveRecord::Base.connection.disable_referential_integrity
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `disable_referential_integrity`, [...]
    RUBY
  end

  it 'flags the use of disable_referential_integrity with a nil receiver' do
    expect_offense(<<~RUBY)
      class Foo ; disable_referential_integrity ; end
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `disable_referential_integrity`, [...]
    RUBY
  end

  it 'flags the use of disable_referential_integrity when passing a block' do
    expect_offense(<<~RUBY)
      class Foo ; disable_referential_integrity { :foo } ; end
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `disable_referential_integrity`, [...]
    RUBY
  end
end
