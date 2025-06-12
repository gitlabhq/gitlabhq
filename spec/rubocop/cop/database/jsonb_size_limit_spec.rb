# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/jsonb_size_limit'

RSpec.describe RuboCop::Cop::Database::JsonbSizeLimit, feature_category: :database do
  it 'adds an offense when the limit is not provided' do
    expect_offense(<<~RUBY)
        class MyModel < ApplicationRecord
          validates :metadata, json_schema: { filename: 'metadata' }
          ^^^^^^^^^ Add `size_limit` to prevent unbounded jsonb growth. [...]
        end
    RUBY
  end

  it 'adds an offense when the limit is nil' do
    expect_offense(<<~RUBY)
        class MyModel < ApplicationRecord
          validates :metadata, json_schema: { filename: 'metadata', size_limit: nil }
          ^^^^^^^^^ Add `size_limit` to prevent unbounded jsonb growth. [...]
        end
    RUBY
  end

  it 'adds no offense when the limit is provided' do
    expect_no_offenses(<<~RUBY)
        class MyModel < ApplicationRecord
          validates :metadata, json_schema: { filename: 'metadata', size_limit: 64.kilobytes }
        end
    RUBY
  end
end
