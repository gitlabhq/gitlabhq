# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/rescue_query_canceled'

RSpec.describe RuboCop::Cop::Database::RescueQueryCanceled do
  it 'flags the use of ActiveRecord::QueryCanceled' do
    expect_offense(<<~RUBY)
      begin
        do_something
      rescue ActiveRecord::QueryCanceled => e
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid rescuing the `ActiveRecord::QueryCanceled` [...]
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
