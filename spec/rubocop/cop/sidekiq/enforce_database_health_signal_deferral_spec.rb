# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/sidekiq/enforce_database_health_signal_deferral'

RSpec.describe RuboCop::Cop::Sidekiq::EnforceDatabaseHealthSignalDeferral, feature_category: :database do
  it 'adds an offense when worker has low urgency and does not defer to database health signal' do
    expect_offense(<<~RUBY)
        class SomeWorker
        ^^^^^^^^^^^^^^^^ Low urgency workers should have the option to be deferred based on the database health [...]
          include ApplicationWorker

          urgency :low
        end
    RUBY
  end

  it 'adds no offense when worker has low urgency and defer to database health signal' do
    expect_no_offenses(<<~RUBY)
        class SomeWorker
          include ApplicationWorker

          urgency :low
          defer_on_database_health_signal :gitlab_main, [:my_table], 1.minute
        end
    RUBY
  end

  it 'adds no offense when worker urgency is other than low' do
    expect_no_offenses(<<~RUBY)
        class SomeWorker
          include ApplicationWorker

          urgency :high
        end
    RUBY
  end
end
