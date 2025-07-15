# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/rescue_statement_timeout'

RSpec.describe RuboCop::Cop::Database::RescueStatementTimeout do
  it 'flags the use of ActiveRecord::StatementTimeout' do
    expect_offense(<<~RUBY)
      begin
        do_something
      rescue ActiveRecord::StatementTimeout => e
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid rescuing the `ActiveRecord::StatementTimeout` [...]
        try_something_else
      end
    RUBY
  end

  it 'does not flag a different exception' do
    expect_no_offenses(<<~RUBY)
      begin
        do_something
      rescue ActiveRecord::RecordNotFound => e
        try_something_else
      end
    RUBY
  end
end
