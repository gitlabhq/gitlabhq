# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/avoid_using_connection_execute'

RSpec.describe RuboCop::Cop::Database::AvoidUsingConnectionExecute, feature_category: :database do
  it 'adds an offense when the using connection.execute' do
    expect_offense(<<~RUBY)
        class MyModel < ApplicationRecord
          def execute
            connection.execute('SELECT * FROM my_models LIMIT 1').to_a
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ The `connection.execute` method always runs [...]
          end
        end
    RUBY
  end

  it 'adds no offense if only calls for execute' do
    expect_no_offenses(<<~RUBY)
        class MyModel < ApplicationRecord
          def execute
            execute('SELECT * FROM my_models LIMIT 1').to_a
          end
        end
    RUBY
  end
end
