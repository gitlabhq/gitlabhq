# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/scalability/random_cron_schedule'

RSpec.describe RuboCop::Cop::Scalability::RandomCronSchedule, feature_category: :scalability do
  context 'when using Kernel#rand in cron_job setting' do
    it 'registers an offense' do
      expect_offense(<<~'RUBY')
        Settings.cron_jobs["my_worker"]["cron"] ||= "#{rand(60)} * * * * UTC"
                                                       ^^^^^^^^ Avoid randomized cron expressions. [...]
      RUBY
    end
  end

  context 'when using Random#rand in cron_job setting' do
    it 'registers an offense' do
      expect_offense(<<~'RUBY')
        Settings.cron_jobs["my_worker"]["cron"] ||= "#{Random.rand(60)} * * * * UTC"
                                                       ^^^^^^^^^^^^^^^ Avoid randomized cron expressions. [...]
      RUBY
    end
  end

  context 'when using static expression in cron_job setting' do
    it 'does not register an offense' do
      expect_no_offenses(<<~'RUBY')
        Settings.cron_jobs["my_worker"]["cron"] ||= "5 * * * * UTC"
      RUBY
    end
  end

  context 'when using random in other settings' do
    it 'does not register an offense' do
      expect_no_offenses(<<~'RUBY')
        Settings.other_setting = "#{rand(60)} is OK"
      RUBY
    end
  end
end
