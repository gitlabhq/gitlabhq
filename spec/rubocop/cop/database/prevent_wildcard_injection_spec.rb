# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/prevent_wildcard_injection'

RSpec.describe RuboCop::Cop::Database::PreventWildcardInjection, feature_category: :database do
  let(:offense_message) { "Wildcard injection vulnerability detected, [...]" }

  it 'adds an offense when using like with interpolation in same string' do
    expect_offense(<<~RUBY)
      class MyModel < ApplicationRecord
        scope :search, ->(pattern) { where("name LIKE '%\#{pattern}%'") }
                                     ^^^^^ #{offense_message}
      end
    RUBY
  end

  it 'adds an offense when using like with string interpolation in parameter' do
    expect_offense(<<~RUBY)
      class MyModel < ApplicationRecord
        scope :search, ->(pattern) { where('name LIKE ?', "\#{pattern}%") }
                                     ^^^^^ #{offense_message}
      end
    RUBY
  end

  it 'adds an offense when using single quotes for SQL and interpolation in parameter' do
    expect_offense(<<~RUBY)
      class MyModel < ApplicationRecord
        scope :with_url_prefix, ->(prefix) { where('url LIKE ?', "\#{prefix}%") }
                                             ^^^^^ #{offense_message}
      end
    RUBY
  end

  it 'adds an offense when using like with interpolation outside of scope' do
    expect_offense(<<~RUBY)
      class MyModel < ApplicationRecord
        def self.search(pattern)
          where("name LIKE '%\#{pattern}%'")
          ^^^^^ #{offense_message}
        end
      end
    RUBY
  end

  it 'adds an offense when using where not' do
    expect_offense(<<~RUBY)
      class MyModel < ApplicationRecord
        def self.search_not(pattern)
          where.not("name LIKE '%\#{pattern}%'")
                ^^^ #{offense_message}
        end
      end
    RUBY
  end

  it 'adds an offense when using exists' do
    expect_offense(<<~RUBY)
      class MyModel < ApplicationRecord
        def self.search_exists?(pattern)
          exists?("name LIKE '%\#{pattern}%'")
          ^^^^^^^ #{offense_message}
        end
      end
    RUBY
  end

  it 'adds no offense when using sanitize_sql_like' do
    expect_no_offenses(<<~RUBY)
      class MyModel < ApplicationRecord
        scope :find_by_pattern, ->(pattern) { where("title LIKE ?", sanitize_sql_like(pattern)) }
      end
    RUBY
  end

  it 'adds no offense when not using LIKE' do
    expect_no_offenses(<<~RUBY)
      class MyModel < ApplicationRecord
        scope :find_by_name, ->(name) { where("title = ?", "\#{name}") }
      end
    RUBY
  end

  it 'adds no offense when LIKE is used without interpolation' do
    expect_no_offenses(<<~RUBY)
      class MyModel < ApplicationRecord
        scope :find_by_prefix, -> { where("title LIKE 'prefix%'") }
      end
    RUBY
  end

  it 'adds no offense when using Gitlab::SQL::Glob.to_like' do
    expect_no_offenses(<<~RUBY)
      class MyModel < ApplicationRecord
        def environments_for_scope(scope)
          quoted_scope = Gitlab::SQL::Glob.q(scope)
          where("name LIKE (\#{Gitlab::SQL::Glob.to_like(quoted_scope)})")
        end
      end
    RUBY
  end

  it 'adds no offense when using sanitized variables' do
    expect_no_offenses(<<~RUBY)
      class MyModel < ApplicationRecord
        scope :search, ->(query) { where('name ILIKE ?', "%\#{sanitized_query}%") }
      end
    RUBY
  end
end
