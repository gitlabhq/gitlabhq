# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/sidekiq_api_usage'

RSpec.describe RuboCop::Cop::SidekiqApiUsage do
  let(:msg) { described_class::MSG }

  context 'when calling Sidekiq::Worker' do
    it 'registers no offences for calling skipping_transaction_check' do
      expect_no_offenses(<<~PATTERN)
        Sidekiq::Worker.skipping_transaction_check do
        end
      PATTERN
    end

    it 'registers no offences for calling raise_inside_transaction_exception' do
      expect_no_offenses(<<~PATTERN)
        Sidekiq::Worker.raise_inside_transaction_exception(cause: "testing")
      PATTERN
    end

    it 'registers no offences for calling raise_exception_for_being_inside_a_transaction?' do
      expect_no_offenses(<<~PATTERN)
        return if Sidekiq::Worker.raise_exception_for_being_inside_a_transaction?
      PATTERN
    end

    it 'registers no offences for calling .via' do
      expect_no_offenses(<<~PATTERN)
        Sidekiq::Client.via { "testing" }
      PATTERN
    end

    it 'registers offence for calling other Sidekiq::Client methods' do
      expect_offense(<<~PATTERN)
        Sidekiq::Client.push('test')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence for calling other Sidekiq::Worker methods' do
      expect_offense(<<~PATTERN)
        Sidekiq::Worker.drain_all
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end
  end

  it 'does not registers offence when calling Sidekiq::Testing' do
    expect_no_offenses(<<~PATTERN)
      Sidekiq::Testing.inline! do
        create_real_projects!
        create_large_projects!
      end
    PATTERN
  end

  it 'registers offence when calling Sidekiq API' do
    expect_offense(<<~PATTERN)
      Sidekiq::Queue.new('testing').all
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
    PATTERN
  end

  it 'registers offence when assigning Sidekiq API classes' do
    expect_offense(<<~PATTERN)
      retry_set = Sidekiq::RetrySet.new
                  ^^^^^^^^^^^^^^^^^^^^^ #{msg}
    PATTERN
  end
end
