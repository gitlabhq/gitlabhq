# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/establish_connection'

RSpec.describe RuboCop::Cop::Database::EstablishConnection do
  it 'flags the use of ActiveRecord::Base.establish_connection' do
    expect_offense(<<~CODE)
      ActiveRecord::Base.establish_connection
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't establish new database [...]
    CODE
  end

  it 'flags the use of ActiveRecord::Base.establish_connection with arguments' do
    expect_offense(<<~CODE)
      ActiveRecord::Base.establish_connection(:foo)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't establish new database [...]
    CODE
  end

  it 'flags the use of SomeModel.establish_connection' do
    expect_offense(<<~CODE)
      SomeModel.establish_connection
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't establish new database [...]
    CODE
  end
end
