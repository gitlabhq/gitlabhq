# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/database/multiple_databases'

RSpec.describe RuboCop::Cop::Database::MultipleDatabases do
  subject(:cop) { described_class.new }

  it 'flags the use of ActiveRecord::Base.connection' do
    expect_offense(<<~SOURCE)
    ActiveRecord::Base.connection.inspect
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use methods from ActiveRecord::Base, [...]
    SOURCE
  end
end
