# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/multiple_databases'

RSpec.describe RuboCop::Cop::Database::MultipleDatabases do
  it 'flags the use of ActiveRecord::Base.connection' do
    expect_offense(<<~SOURCE)
    ActiveRecord::Base.connection.inspect
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use methods from ActiveRecord::Base, [...]
    SOURCE
  end

  it 'flags the use of ::ActiveRecord::Base.connection' do
    expect_offense(<<~SOURCE)
    ::ActiveRecord::Base.connection.inspect
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use methods from ActiveRecord::Base, [...]
    SOURCE
  end

  described_class::ALLOWED_METHODS.each do |method_name|
    it "does not flag use of ActiveRecord::Base.#{method_name}" do
      expect_no_offenses(<<~SOURCE)
        ActiveRecord::Base.#{method_name} do
          Project.save
        end
      SOURCE
    end
  end
end
