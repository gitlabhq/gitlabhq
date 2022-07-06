# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/database/rescue_query_canceled'

RSpec.describe RuboCop::Cop::Database::RescueQueryCanceled do
  subject(:cop) { described_class.new }

  it 'flags the use of ActiveRecord::QueryCanceled' do
    expect_offense(<<~CODE)
      begin
        do_something
      rescue ActiveRecord::QueryCanceled => e
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid rescuing the `ActiveRecord::QueryCanceled` [...]
        try_something_else
      end
    CODE
  end

  it 'does not flag a different exception' do
    expect_no_offenses(<<~CODE)
      begin
        do_something
      rescue ActiveRecord::RecordNotFound => e
        try_something_else
      end
    CODE
  end
end
