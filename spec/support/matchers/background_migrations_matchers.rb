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
      "not scheduled in expected time! Expected any of `#{BackgroundMigrationWorker.jobs.map { |j| j['args'] }}` to be `#{[migration, expected]}` " \
      "and any of `#{BackgroundMigrationWorker.jobs.map { |j| j['at'].to_i }}` to be `#{delay.to_i + Time.now.to_i}` (`#{delay.to_i}` + `#{Time.now.to_i}`)."
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

RSpec::Matchers.define :be_scheduled_migration_with_multiple_args do |*expected|
  match do |migration|
    BackgroundMigrationWorker.jobs.any? do |job|
      args = job['args'].size == 1 ? [BackgroundMigrationWorker.jobs[0]['args'][0], []] : job['args']
      args[0] == migration && compare_args(args, expected)
    end
  end

  failure_message do |migration|
    "Migration `#{migration}` with args `#{expected.inspect}` not scheduled!"
  end

  def compare_args(args, expected)
    args[1].map.with_index do |arg, i|
      arg.is_a?(Array) ? same_arrays?(arg, expected[i]) : arg == expected[i]
    end.all?
  end

  def same_arrays?(arg, expected)
    arg.sort == expected.sort
  end
end
