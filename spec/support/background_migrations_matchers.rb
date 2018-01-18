RSpec::Matchers.define :be_scheduled_delayed_migration do |delay, *expected|
  include ActionView::Helpers::DateHelper

  match do |migration|
    @delay = delay
    @migration = migration
    @expected = expected

    jobs_with_expected_args.any? do |job|
      job['at'].to_i == expected_time
    end
  end

  def expected_time
    (@delay.to_i + Time.now.to_i)
  end

  def expected_args
    [migration_name, @expected]
  end

  def migration_name
    @migration.is_a?(Class) ? @migration.to_s.demodulize : @migration
  end

  def jobs_with_expected_args
    BackgroundMigrationWorker.jobs.select do |job|
      job['args'] == expected_args
    end
  end

  def found_args
    BackgroundMigrationWorker.jobs.map {|job| job['args'] }
  end

  def found_times
    jobs_with_expected_args.map {|job| job['at'].to_i }
                           .map {|time| time_from_now(time) }
  end

  def expected_time_in_words
    time_from_now(expected_time)
  end

  def time_from_now(time)
    distance_of_time_in_words(Time.now, Time.at(time))
  end

  failure_message do |migration|
    if jobs_with_expected_args.any?
      "Migration `#{migration_name}` with args `#{@expected.inspect}`" \
       " should have been scheduled in #{expected_time_in_words} but" \
       " was found in #{found_times}"
     else
      "Migration `#{migration_name}` not found scheduled with args `#{@expected.inspect}`" \
       " but was found with args #{found_args}"
    end
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
