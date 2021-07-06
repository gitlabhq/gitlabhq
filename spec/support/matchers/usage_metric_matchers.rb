# frozen_string_literal: true

RSpec::Matchers.define :have_usage_metric do |key_path|
  match do |payload|
    payload = payload.deep_stringify_keys

    key_path.split('.').each do |part|
      break false unless payload&.has_key?(part)

      payload = payload[part]
    end
  end

  failure_message do
    "Payload does not contain metric with key path: '#{key_path}'"
  end

  failure_message_when_negated do
    "Payload contains restricted metric with key path: '#{key_path}'"
  end
end
