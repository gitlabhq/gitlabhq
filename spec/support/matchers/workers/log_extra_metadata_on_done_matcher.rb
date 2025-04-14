# frozen_string_literal: true

RSpec::Matchers.define :log_extra_metadata_on_done do |expected|
  match do |worker|
    actual_extras = worker.logging_extras

    expected_extras = expected.transform_keys do |k|
      "#{::ApplicationWorker::LOGGING_EXTRA_KEY}.#{worker.class.name.gsub('::', '_').underscore}.#{k}"
    end

    expect(actual_extras).to include(expected_extras)
  end

  failure_message do |worker|
    "expected #{worker.class.name} to log extra metadata #{expected} on done " \
      "but actual extras contained #{worker.logging_extras}"
  end
end
