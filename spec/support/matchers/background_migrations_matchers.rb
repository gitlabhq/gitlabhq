# frozen_string_literal: true

RSpec::Matchers.define :be_scheduled_delayed_migration do |delay, *expected|
  match do |migration|
    BackgroundMigrationWorker.jobs.any? do |job|
      job['args'] == [migration, expected] &&
        job['at'].to_i == (delay.to_i + Time.now.to_i)
    end
  end

  failure_message do |migration|
    "Migration `#{migration}` with args `#{expected.inspect}` " \
      'not scheduled in expected time!'
  end
end

RSpec::Matchers.define :be_scheduled_migration do |*expected|
  match do |migration|
    BackgroundMigrationWorker.jobs.any? do |job|
      args = job['args'].size == 1 ? [BackgroundMigrationWorker.jobs[0]['args'][0], []] : job['args']
      args == [migration, expected]
    end
  end

  failure_message do |migration|
    "Migration `#{migration}` with args `#{expected.inspect}` not scheduled!"
  end
end
